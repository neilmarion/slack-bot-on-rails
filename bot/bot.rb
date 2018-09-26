class Bot < SlackRubyBot::Bot
  # Getting user slack user ids https://slack.com/api/users.list?token=xoxp-5132160299-162649861808-214565164807-14d6f103c6022ed767e25f26a027ffaa&pretty=1

  DEV_IDS = {
    ptorre: "U890X3XL2",
    jessc: "U6N5LSTJR",
    dc: "U5RT71ZKQ",
    earle: "U0YL17DBQ",
    francis: "U4TDX4QSH",
    nmfdelacruz: "U4SK3RBPS",
    rickdtrick: "U5VFECCPM",
    angelique: "U4DTJAPU3",
    pjlim: "U5ALLTPGF",
    tony: "U053W4Q99",
  }

  QA_IDS = {
    mikej: "U5134F0RE",
    rjomosura: "U63NEQ087",
  }

  TECH_OPS = [:jessc, :earle, :francis, :angelique, :ptorre]
  MOBILE = [:dc, :nmfdelacruz]
  COMMERCIAL = [:nmfdelacruz, :dc, :rickdtrick]
  FRONTEND = [:rickdtrick, :pjlim]
  ALL = [
    :ptorre,
    :jessc,
    :dc,
    :earle,
    :francis,
    :nmfdelacruz,
    :rickdtrick,
    :angelique,
  ]

  command '--help' do |client, data, match|
    string = "```
plankbot, version 0.3, https://github.com/neilmarion/slack-bot-on-rails

usage: @plankbot review -R <repo name> -P <PR number> [-T <team>] [-X member/s]
Chooses at most two code reviewers for a PR

Options:
  -R    repository name
  -P    pull request number
  -T    team name
  -X    ommit member, comma separated and no spaces between
  -Q    staging branch (request for QA review)
  -A    Add another code reviewer, comma separated and no spaces between

teams:
  tech_ops (jessc, earle, francis, angelique)
  fca_v2 (earle, francis)
  mobile (ptorre, dc, nmfdelacruz)
  commercial (nmfdelacruz, ptorre, dc, rickdtrick)
  frontend (rickdtrick, francis, pjlim)

members:
  angelique, dc, earle, francis, jessc, nmfdelacruz, ptorre, rickdtrick, pjlim, tony

examples:
  1. @plankbot review -R first-circle-app -P 6672 -X nmfdelacruz,rickdtrick
  2. @plankbot review -R fca_mobile_react -P 102 -T mobile
  3. @plankbot review -R first-circle-account -P 13 -T fca_v2 -X francis
  4. @plankbot review -R first-circle-app -P 6672 -Q staging-apollo
  5. @plankbot review -R first-circle-app -P 321 -A tony,earle

PROCESS SUMMARY:
      make branch
    +-> PR (WIP label)
    |     writing code
    |       writing tests
    |         PR (REVIEW label)
    +---------- QA and code review
                  branch merge to master
                    production smoke testing

wake up:
  Go to http://plankbotfc.herokuapp.com/
```"

    client.say(channel: data.channel, text: string)
  end

  def self.build_url(options)
    "https://github.com/carabao-capital/#{options[:repo]}/pull/#{options[:pr_no]}"
  end

  def self.team(team)
    case team
    when "tech_ops"
      TECH_OPS
    when "mobile"
      MOBILE
    when "commercial"
      COMMERCIAL
    when "frontend"
      FRONTEND
    else
      ALL
    end
  end

  def self.randomize(team, members_to_ommit, user_id)
    remaining_members = team - members_to_ommit.map(&:to_sym)

    dev_ids = remaining_members.map{|m| DEV_IDS[m] }
    dev_ids = dev_ids - [user_id]
    chosen_dev_ids = []

    if dev_ids.size <= 2
      return dev_ids
    else
      first_chosen = dev_ids[Random.rand(0...dev_ids.size)]
      chosen_dev_ids << first_chosen

      loop do
        second_chosen = dev_ids[Random.rand(0...dev_ids.size)]
        if second_chosen != first_chosen
          chosen_dev_ids << second_chosen
          break
        end
      end
    end

    chosen_dev_ids
  end

  command 'review' do |client, data, match|
    string = match['expression']
    string_array = string.split(' ')

    url_options = {}
    chosen_team = ALL
    members_to_ommit = []
    staging_env = nil
    additional_reviewer_ids = []

    string_array.each_with_index do |e, counter|
      next if counter % 2 == 1

      case e
      when "-R"
        repo = string_array[counter + 1].split("|").last.gsub(/>/, '')
        url_options[:repo] = repo
      when "-P"
        url_options[:pr_no] = string_array[counter + 1]
      when "-T"
        chosen_team = team(string_array[counter + 1])
      when "-X"
        members_to_ommit = string_array[counter + 1].split(',')
      when "-Q"
        staging_env = string_array[counter + 1]
      when "-A"
        additional_reviewer_ids = string_array[counter + 1].split(',').map{|x| DEV_IDS[x.to_sym]}
      end
    end

    additional_reviewer_ids << DEV_IDS[:rickdtrick] if url_options[:repo] == 'first-circle-account' && data.user != 'rickdtrick'

    chosen_reviewer_ids = randomize(chosen_team, members_to_ommit, data.user) + additional_reviewer_ids

    chosen_reviewer_ids.map{|e| "<@#{e}>"}

    qa_team_call_out_string = if staging_env
      "Also, QA team (#{QA_IDS.values.map{|id| "<@#{id}>"}.join("or ")}) to review it in #{staging_env}"
    end

    message = "Hi #{chosen_reviewer_ids.map{|e| "<@#{e}>"}.join(" and ")}! <@#{data.user}> asked to code-review #{build_url(url_options)}. #{qa_team_call_out_string}"
    client.say({
      channel: data.channel,
      text: message,
    })
  end
end

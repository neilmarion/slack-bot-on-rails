class Bot < SlackRubyBot::Bot
  # Getting user slack user ids https://slack.com/api/users.list?token=xoxp-5132160299-162649861808-214565164807-14d6f103c6022ed767e25f26a027ffaa&pretty=1

  DEV_IDS = {
    rgabriel: "U6JUFRGUU",
    ptorre: "U890X3XL2",
    jessc: "U6N5LSTJR",
    dc: "U5RT71ZKQ",
    earle: "U0YL17DBQ",
    francis: "U4TDX4QSH",
    nmfdelacruz: "U4SK3RBPS",
    rickdtrick: "U5VFECCPM",
    angelique: "U4DTJAPU3",
  }

  TECH_OPS = [:rgabriel, :jessc, :earle, :francis, :angelique]
  FCA_V2 = [:rgabriel, :earle, :francis]
  MOBILE = [:ptorre, :dc, :nmfdelacruz]
  COMMERCIAL = [:nmfdelacruz, :ptorre, :dc, :rickdtrick]
  FRONTEND = [:rickdtrick, :francis]
  ALL = [
    :rgabriel,
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

teams:
  tech_ops (rgabriel, jessc, earle, francis, angelique)
  fca_v2 (rgabriel, earle, francis)
  mobile (ptorre, dc, nmfdelacruz)
  commercial (nmfdelacruz, ptorre, dc, rickdtrick)
  frontend (rickdtrick, francis)

members:
  angelique, dc, earle, francis, jessc, nmfdelacruz, ptorre, rgabriel, rickdtrick

examples:
  1. @plankbot review -R first-circle-app -P 6672 -X nmfdelacruz,rickdtrick
  2. @plankbot review -R fca_mobile_react -P 102 -T mobile
  3. @plankbot review -R first-circle-account -P 13 -T fca_v2 -X francis

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
    when "fca_v2"
      FCA_V2
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

    string_array.each_with_index do |e, counter|
      next if counter % 2 == 1

      case e
      when "-R"
        url_options[:repo] = string_array[counter + 1]
      when "-P"
        url_options[:pr_no] = string_array[counter + 1]
      when "-T"
        chosen_team = team(string_array[counter + 1])
      when "-X"
        members_to_ommit = string_array[counter + 1].split(',')
      end
    end

    chosen_reviewer_ids = randomize(chosen_team, members_to_ommit, data.user)

    chosen_reviewer_ids.map{|e| "<@#{e}>"}

    message = "Hi #{chosen_reviewer_ids.map{|e| "<@#{e}>"}.join(" and ")}! <@#{data.user}> asked to review #{build_url(url_options)}"
    client.say({
      channel: data.channel,
      text: message,
    })
  end
end

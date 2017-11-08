class Bot < SlackRubyBot::Bot
  @id = 0

  SENIOR_DEV_IDS = [
    "U4SK3RBPS",
    "U5AG3CY7M",
    "U6N5LSTJR",
  ];

  DEV_IDS = [
    "U5RT71ZKQ",
    "U0YL17DBQ",
    "U4TDX4QSH",
    "U5VFECCPM",
    "U6JUFRGUU",
  ];

  # @dc = "U5RT71ZKQ"
  # @earle = "U0YL17DBQ"
  # @francis = "U4TDX4QSH"
  # @nmfdelacruz = "U4SK3RBPS"
  # @sachink = "U5X3KN2AV"
  # @vicente = "U5AG3CY7M"
  # @yogesh.khather = "U4X6FDG95"
  # @rickdtrick = "U5VFECCPM"

  def self.next_id
    @id = @id % 10 + 1
  end

  command 'say' do |client, data, match|
    Rails.cache.write next_id, { text: match['expression'] }
    client.say(channel: data.channel, text: match['expression'])
  end

  command 'who is the handsomest guy in tech?' do |client, data, match|
    client.say(channel: data.channel, text: "It's Brian 'the Dragon' McKiernan!! Chat him at <@U2DHPSA9J>")
  end

  command 'reviewer for' do |client, data, match|
    senior_dev_ids = SENIOR_DEV_IDS - [data.user]
    dev_ids = DEV_IDS - [data.user]

    senior_dev_index = Random.rand(0...senior_dev_ids.size)
    dev_index = Random.rand(0...dev_ids.size)

    senior_dev_id = senior_dev_ids[senior_dev_index]
    dev_id = dev_ids[dev_index]

    pr_no = match['expression']

    message = "Hi <@#{dev_id}> and <@#{senior_dev_id}>! " +
      "<@#{data.user}> asked you to review this PR here https://github.com/carabao-capital/first-circle-app/pull/#{pr_no}"

    client.say({
      channel: data.channel,
      text: message,
    })
  end
end

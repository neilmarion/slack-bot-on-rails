class Bot < SlackRubyBot::Bot
  @id = 0

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
end

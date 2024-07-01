class Whatsapp
  # Followed this guide: https://medium.com/@rishicentury/how-to-use-whatsapp-cloud-api-6c4b4a22fc34

  def self.send(str, number: "17737898255")
    raise "Need to specify what you want to send" if str.blank?

    response = if str.is_a?(Symbol)
      send_template(str, number)
    else
      send_text(str, number)
    end

    raise "Unexpected response: #{response.status} - #{response.body}" if response.status != 200
  end

  def self.send_text(text, number: "17737898255")
    raise "Need to specify text to send" if text.blank?

    response = Faraday.post("https://graph.facebook.com/v19.0/320958887765426/messages") do |req|
      req.headers["Authorization"] = "Bearer #{Setting.whatsapp_key}"
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate({
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: number,
        type: "text",
        text: {
          body: text
        }
      })
    end
  end

  def self.send_template(name = :hello_world, number: "17737898255")
    raise "Need to specify a template name" if name.blank?

    response = Faraday.post("https://graph.facebook.com/v19.0/320958887765426/messages") do |req|
      req.headers["Authorization"] = "Bearer #{Setting.whatsapp_key}"
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate({
        messaging_product: "whatsapp",
        to: number,
        type: "template",
        template: {
          name: name,
          language: {
            code: "en_US"
          }
        }
      })
    end
  end
end

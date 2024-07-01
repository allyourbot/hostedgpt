class WhatsappController < ApplicationController
  protect_from_forgery except: :create
  skip_before_action :authenticate_user!

  def create
    # render plain: params["hub.challenge"], status: :ok

    # if params[:entry][0][:id] == "332066249987383"
    #   binding.pry
    # end

    render plain: "OK", status: :ok
  end

  private

  def callback
    params.dig(:entry, 0, :changes, 0)
  end
end


#   curl -i -X POST \
#   https://graph.facebook.com/v19.0/320958887765426/messages \
#   -H 'Authorization: Bearer abc123' \
#   -H 'Content-Type: application/json' \
#   -d '{ "messaging_product": "whatsapp", "to": "17737898255", "type": "template", "template": { "name": "hello_world", "language": { "code": "en_US" } } }'



# {"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"},

# "statuses"=>[{"id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgARGBJBODFGN0ExNDc2NUUzODBFNTEA", "status"=>"read", "timestamp"=>"1715986294", "recipient_id"=>"17737898255"}]}, "field"=>"messages"}]}], "whatsapp"=>{"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"332066249987383", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"},

# "statuses"=>[{"id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgARGBJBODFGN0ExNDc2NUUzODBFNTEA", "status"=>"read", "timestamp"=>"1715986294", "recipient_id"=>"17737898255"}]}, "field"=>"messages"}]}]}}





# {"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"},

# "statuses"=>[{"id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgARGBJBODFGN0ExNDc2NUUzODBFNTEA", "status"=>"delivered", "timestamp"=>"1715986294", "recipient_id"=>"17737898255", "conversation"=>{"id"=>"2bb8fba1d906609da4c5cbdac61f5bf1", "origin"=>{"type"=>"utility"}}, "pricing"=>{"billable"=>true, "pricing_model"=>"CBP", "category"=>"utility"}}]}, "field"=>"messages"}]}], "whatsapp"=>{"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"332066249987383", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"},

# "statuses"=>[{"id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgARGBJBODFGN0ExNDc2NUUzODBFNTEA", "status"=>"delivered", "timestamp"=>"1715986294", "recipient_id"=>"17737898255", "conversation"=>{"id"=>"2bb8fba1d906609da4c5cbdac61f5bf1", "origin"=>{"type"=>"utility"}}, "pricing"=>{"billable"=>true, "pricing_model"=>"CBP", "category"=>"utility"}}]}, "field"=>"messages"}]}]}}





# {"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"},

# "statuses"=>[{"id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgARGBJBODFGN0ExNDc2NUUzODBFNTEA", "status"=>"sent", "timestamp"=>"1715986294", "recipient_id"=>"17737898255", "conversation"=>{"id"=>"2bb8fba1d906609da4c5cbdac61f5bf1", "expiration_timestamp"=>"1716070440", "origin"=>{"type"=>"utility"}}, "pricing"=>{"billable"=>true, "pricing_model"=>"CBP", "category"=>"utility"}}]}, "field"=>"messages"}]}], "whatsapp"=>{"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"332066249987383", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"},

# "statuses"=>[{"id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgARGBJBODFGN0ExNDc2NUUzODBFNTEA", "status"=>"sent", "timestamp"=>"1715986294", "recipient_id"=>"17737898255", "conversation"=>{"id"=>"2bb8fba1d906609da4c5cbdac61f5bf1", "expiration_timestamp"=>"1716070440", "origin"=>{"type"=>"utility"}}, "pricing"=>{"billable"=>true, "pricing_model"=>"CBP", "category"=>"utility"}}]}, "field"=>"messages"}]}]}}





# {"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"},

# "statuses"=>[{"id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgARGBIzMzIyMkQ1MUJCRTRFMTcwOTEA", "status"=>"read", "timestamp"=>"1715985847", "recipient_id"=>"17737898255"}]}, "field"=>"messages"}]}], "whatsapp"=>{"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"332066249987383", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"},

# "statuses"=>[{"id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgARGBIzMzIyMkQ1MUJCRTRFMTcwOTEA", "status"=>"read", "timestamp"=>"1715985847", "recipient_id"=>"17737898255"}]}, "field"=>"messages"}]}]}}





# # # reply


# {"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"}, "contacts"=>[{"profile"=>{"name"=>"Keith Schacht"}, "wa_id"=>"17737898255"}], "messages"=>[{"from"=>"17737898255", "id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgASGBQzQUFBNTU5NEVCRTFBNzlCRkY4RAA=", "timestamp"=>"1715986308", "text"=>{"body"=>"Yes"}, "type"=>"text"}]}, "field"=>"messages"}]}], "whatsapp"=>{"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"332066249987383", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"17372885811", "phone_number_id"=>"320958887765426"}, "contacts"=>[{"profile"=>{"name"=>"Keith Schacht"}, "wa_id"=>"17737898255"}], "messages"=>[{"from"=>"17737898255", "id"=>"wamid.HBgLMTc3Mzc4OTgyNTUVAgASGBQzQUFBNTU5NEVCRTFBNzlCRkY4RAA=", "timestamp"=>"1715986308", "text"=>{"body"=>"Yes"}, "type"=>"text"}]}, "field"=>"messages"}]}]}}

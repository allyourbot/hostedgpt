require "test_helper"
require "./test/lib/active_storage/service/shared_service_tests"

class ActiveStorage::Service::PublicPostgresqlTest < ActiveSupport::TestCase
  SERVICE = ActiveStorage::Service.configure(:tmp_public, { tmp_public: { service: "Postgresql", public: true }})
  include ActiveStorage::Service::SharedServiceTests

  test "public URL generation" do
    url = @service.url(@key, disposition: :inline, filename: ActiveStorage::Filename.new("avatar.png"), content_type: "image/png")

    assert_match(/^\/rails\/active_storage\/postgresql\/.*\/avatar\.png/, url)
  end
end

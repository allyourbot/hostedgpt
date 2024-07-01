require "./test/lib/active_storage/service/shared_service_tests"

class ActiveStorage::PostgresqlTest < ActiveSupport::TestCase
  SERVICE = ActiveStorage::Service.configure(:postgresql, { postgresql: { service: "Postgresql" } })
  include ActiveStorage::Service::SharedServiceTests

  test "uploading with service metadata" do
    begin
      key  = SecureRandom.base58(24)
      data = "Something else entirely!"
      @service.upload(key, StringIO.new(data), checksum: Digest::MD5.base64digest(data), irrelevant_metadata: "ignored")
      assert_equal data, @service.download(key)
    ensure
      @service.delete key
    end
  end

  test "uploading file with integrity" do
    begin
      key  = SecureRandom.base58(24)
      data = "Something else entirely!"
      file = Tempfile.open("upload")
      file.write(data)
      file.rewind
      @service.upload(key, file, checksum: Digest::MD5.base64digest(data))
      assert_equal data, @service.download(key)
    ensure
      @service.delete key
    end
  end

  test "uploading file without integrity" do
    begin
      key  = SecureRandom.base58(24)
      data = "Something else entirely!"
      file = Tempfile.open("upload")
      file.write(data)
      file.rewind

      assert_raises(ActiveStorage::IntegrityError) do
        @service.upload(key, file, checksum: Digest::MD5.base64digest("bad data"))
      end

      assert_not @service.exist?(key)
    ensure
      @service.delete key
    end
  end

  test "url generation" do
    assert_match(/^\/rails\/active_storage\/postgresql\/.*\/avatar\.png\?content_type=image%2Fpng&disposition=inline/,
      @service.url(FIXTURE_KEY, expires_in: 5.minutes, disposition: :inline, filename: ActiveStorage::Filename.new("avatar.png"), content_type: "image/png"))
  end

  test "headers_for_direct_upload generation" do
    assert_equal({ "Content-Type" => "application/json" }, @service.headers_for_direct_upload(FIXTURE_KEY, content_type: "application/json"))
  end
end

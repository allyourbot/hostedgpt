module ActiveStorage
  # Wraps a Postgresql database as an Active Storage service. See ActiveStorage::Service for the generic API
  # documentation that applies to all services.
  class Service::PostgresqlService < Service
    def initialize(public: false, **options)
      @public = public
    end

    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        ActiveStorage::Postgresql::File.create!(key: key, io: io, checksum: checksum)
      end
    end

    def download(key)
      if block_given?
        instrument :streaming_download, key: key do
          ActiveStorage::Postgresql::File.open(key) do |file|
            while data = file.read(5.megabytes)
              yield data
            end
          end
        end
      else
        instrument :download, key: key do
          ActiveStorage::Postgresql::File.open(key) do |file|
            file.read
          end
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        ActiveStorage::Postgresql::File.open(key) do |file|
          file.seek(range.first)
          file.read(range.size)
        end
      end
    end

    def delete(key)
      instrument :delete, key: key do
        ActiveStorage::Postgresql::File.find_by(key: key).try(&:destroy)
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        answer = ActiveStorage::Postgresql::File.where(key: key).exists?
        payload[:exist] = answer
        answer
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        ActiveStorage::Postgresql::File.prefixed_with(prefix).destroy_all
      end
    end

    def private_url(key, expires_in:, filename:, content_type:, disposition:, **)
      generate_url(key, expires_in: expires_in, filename: filename, content_type: content_type, disposition: disposition)
    end

    def public_url(key, filename:, content_type: nil, disposition: :attachment, **)
      generate_url(key, expires_in: nil, filename: filename, content_type: content_type, disposition: disposition)
    end

    def url(key, **options)
      super
    rescue NotImplementedError, ArgumentError
      if @public
        public_url(key, **options)
      else
        private_url(key, **options)
      end
    end

    def generate_url(key, expires_in:, filename:, disposition:, content_type:)
      # This is a hack to support reliable system tests. Specifically, URLs for active_storage postgres images begin by hitting:
      #   /rails/active_storage/representations/redirect/:key/:filename?disposition=
      # When that is deciding where to redirect to, it ends up calling generate_url() and disposition gets passed in:
      #   https://github.com/rails/rails/blob/main/activestorage/app/controllers/active_storage/representations/redirect_controller.rb
      # The value of disposition is nil, inline, or attachment. In our code it's always nil but regardless we are overloading
      # disposition by expecting something like "inline-2". If there is a dash, we split on that and assume anything after it is
      # a counter. The only place we're doing this is in image_loader_controller.js and it's for the purpose of a test we wrote
      # in image_test.rb.
      disposition, counter = disposition.to_s.split("-")
      counter = counter.to_i
      # End hack

      instrument :url, key: key do |payload|
        content_disposition = content_disposition_with(type: disposition, filename: filename)
        verified_key_with_expiration = ActiveStorage.verifier.generate(
          {
            key: key,
            disposition: content_disposition,
            content_type: content_type
          },
          expires_in: expires_in,
          purpose: :blob_key
        )

        generated_url = url_helpers.rails_postgresql_service_url(verified_key_with_expiration,
          only_path: true,
          disposition: content_disposition,
          content_type: content_type,
          filename: filename,
          retry_count: counter
        )
        payload[:url] = generated_url

        generated_url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
      instrument :url, key: key do |payload|
        verified_token_with_expiration = ActiveStorage.verifier.generate(
          {
            key: key,
            content_type: content_type,
            content_length: content_length,
            checksum: checksum
          },
          expires_in: expires_in,
          purpose: :blob_token
        )

        generated_url = url_helpers.update_rails_postgresql_service_url(verified_token_with_expiration, **url_options)

        payload[:url] = generated_url

        generated_url
      end
    end

    def headers_for_direct_upload(key, content_type:, **)
      { "Content-Type" => content_type }
    end

    protected

    def url_helpers
      @url_helpers ||= Rails.application.routes.url_helpers
    end

    def url_options
      if ActiveStorage::Current.respond_to?(:url_options)
        ActiveStorage::Current.url_options
      else
        { host: ActiveStorage::Current.host }
      end
    end
  end
end

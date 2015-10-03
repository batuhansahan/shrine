class Shrine
  module Plugins
    module RemoteUrl
      def self.load_dependencies(uploader, downloader: :open_uri, **)
        case downloader
        when :open_uri then require "down"
        end
      end

      def self.configure(uploader, downloader: :open_uri, error_message:, max_size: nil)
        uploader.opts[:remote_url_downloader] = downloader
        uploader.opts[:remote_url_error_message] = error_message
        uploader.opts[:remote_url_max_size] = max_size
      end

      module AttachmentMethods
        def initialize(name, *args)
          super

          module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}_remote_url=(url)
              #{name}_attacher.remote_url = url
            end

            def #{name}_remote_url
              #{name}_attacher.remote_url
            end
          RUBY
        end
      end

      module AttacherMethods
        def remote_url=(url)
          return if url == ""

          if downloaded_file = download(url)
            set(downloaded_file)
          else
            message = shrine_class.opts[:remote_url_error_message]
            message = message.call(url) if message.respond_to?(:call)
            errors << message
            @remote_url = url
          end
        end

        def remote_url
          @remote_url
        end

        private

        def download(url)
          downloader = shrine_class.opts[:remote_url_downloader]
          max_size = shrine_class.opts[:remote_url_max_size]

          if downloader.is_a?(Symbol)
            send(:"download_with_#{downloader}", url, max_size: max_size)
          else
            downloader.call(url, max_size: max_size)
          end
        end

        def download_with_open_uri(url, max_size:)
          Down.download(url, max_size: max_size)
        rescue Down::Error
        end
      end
    end

    register_plugin(:remote_url, RemoteUrl)
  end
end
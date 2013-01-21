require_dependency 'attachments_controller'

module EmbeddedFlash
  module AttachmentsControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        unloadable
        alias_method_chain :download, :embedded_flash
      end
    end

    module InstanceMethods
      def download_with_embedded_flash
        if @attachment.filename =~ /\.swf$/i
          if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
            @attachment.increment_download
          end
          if stale?(:etag => @attachment.digest)
            # always send SWF files inline to avoid security restrictions in Flash Player 10 (and above)
            send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                                            :type => detect_content_type(@attachment),
                                            :disposition => 'inline'
          end
        else
          download_without_embedded_flash
        end
      end
    end
  end
end

unless AttachmentsController.included_modules.include? EmbeddedFlash::AttachmentsControllerPatch
  AttachmentsController.send(:include, EmbeddedFlash::AttachmentsControllerPatch)
end

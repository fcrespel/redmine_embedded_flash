require 'redmine'

Rails.configuration.to_prepare do
  require_dependency 'redmine_embedded_flash/attachments_controller_patch'
end

Redmine::Plugin.register :redmine_embedded_flash do
  name 'Redmine Embedded Flash plugin'
  author 'Fabien Crespel'
  author_url 'mailto:fabien@crespel.net'
  url 'https://github.com/fcrespel/redmine_embedded_flash'
  description 'This plugin lets you embed Flash content in wiki, issues, etc. thanks to the {{flash(file, width, height)}} macro.'
  version '1.0.0'
end

Redmine::WikiFormatting::Macros.register do
  desc "Embed a Flash SWF file. Examples:\n\n<pre>{{flash(websample.swf)}}\n{{flash(http://www.debugmode.com/wink/websample.swf, 271, 151)}}</pre>"
  macro :flash do |o, args|
    # Parse the file argument
    attachment = o.attachments.find_by_filename(args[0]) if o.respond_to?('attachments')
    if attachment
      file_url = url_for(:controller => 'attachments', :action => 'download', :id => attachment, :filename => attachment.filename)
    else
      file_url = args[0].gsub(/<[^\>]+>/, '')
    end

    # Parse width and height arguments
    width = args[1].gsub(/\D/, '') if args[1]
    height = args[2].gsub(/\D/, '') if args[2]
    width ||= 400
    height ||= 300

    # Assign unique number to file
    @flashplayer_num ||= 0
    @flashplayer_num = @flashplayer_num + 1

    # Include SWFObject only once in header
    content_for :header_tags do
      javascript_include_tag 'swfobject.js', :plugin => :redmine_embedded_flash
    end if @flashplayer_num == 1

    # Build the output
    out = <<END
<p id="flashplayer_#{@flashplayer_num}">Your browser cannot display Flash content, please check that Adobe Flash Player is installed<br/><a href="http://get.adobe.com/flashplayer/">Get Flash</a></p>
<script type="text/javascript">
//<![CDATA[
swfobject.embedSWF('#{file_url}', 'flashplayer_#{@flashplayer_num}', '#{width}', '#{height}', '9');
//]]>
</script>
END
    out.html_safe
  end
end

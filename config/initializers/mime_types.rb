# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

Mime::Type.register_alias 'application/x-crossword', :puz

ActionController::Renderers.add :puz do |obj, options|
  filename = options[:filename] || 'crossword.puz'
  str = obj.respond_to?(:to_puz) ? obj.to_puz : obj.to_s
  send_data str, :type => Mime::PUZ
end

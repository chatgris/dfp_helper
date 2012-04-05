module DfpHelper
  class Railtie < Rails::Railtie
    initializer "dfp_helper.view_helpers" do
      ActionView::Base.send :include, ViewHelpers
    end
  end

  module ViewHelpers
    def dfp_helper_slots
      @dfp_helper_slots||=[]
    end
    def dfp_helper_slot(_i, options = {})
      _id = "div-ad-#{options[:index] || dfp_helper_slots.size}"
      _size = options[:size] || _i.match(/\d+x\d+/)[0].split('x')
      dfp_helper_slots << options.merge({:id => _i, :div_id => _id, :size => _size})

      raw <<-END.strip
<!-- #{_i} -->
<div id='#{_id}' class='dfp dfp_#{_size[0]}x#{_size[1]}'>
<script type='text/javascript'>
googletag.cmd.push(function() { googletag.display('#{_id}'); });
</script>
</div>
      END
    end

    def dfp_helper_head(options = nil)
      return unless dfp_helper_slots.size > 0
      o = dfp_helper_slots.collect{|i|
        _targeting = (i[:targeting]||[]).collect{|k,v| ".setTargeting(#{k.to_json}, #{v.to_json})"}.join
        "googletag.defineSlot('#{i[:id]}', [#{i[:size].join(', ')}], '#{i[:div_id]}').addService(googletag.pubads())#{_targeting};"
      }.join("\n")

      raw <<-END.strip
<script type='text/javascript'>
var googletag = googletag || {};
googletag.cmd = googletag.cmd || [];
(function() {
var gads = document.createElement('script');
gads.async = true;
gads.type = 'text/javascript';
var useSSL = 'https:' == document.location.protocol;
gads.src = (useSSL ? 'https:' : 'http:') +
'//www.googletagservices.com/tag/js/gpt.js';
var node = document.getElementsByTagName('script')[0];
node.parentNode.insertBefore(gads, node);
})();
</script>

<script type='text/javascript'>
googletag.cmd.push(function() {
#{o}
#{options}
googletag.pubads().enableSingleRequest();
googletag.enableServices();
});
</script>
      END
    end
  end
end

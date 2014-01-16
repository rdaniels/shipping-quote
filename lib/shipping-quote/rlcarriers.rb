class RLQuote
  attr_accessor :notes


  def initialize(cart_items, config, truck_only)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
    @notes = []
    @xml = Document.new
  end

  # Creates the XML for the request.
  def rate_estimate(destination)
    root = Element.new("FREIGHTQUOTE")
    root.attributes["accept-encoding"] = "deflate;q=0"
    root.attributes["te"] = "deflate;q=0"
    root.attributes["id"] = "5173944631"
    root.attributes["origin"] = "48910" 
    root.attributes["dest"] = destination[:country]
    root.attributes["class1"] = ship_class
    root.attributes["weight1"] = "#tmpweight#"
    root.attributes["delnotify"] = "X"
    root.attributes["hazmat"] = check_ormd
    @xml << root
  end

  #<cfhttp url="http://www.rlcarriers.com/b2brateparam.asp" method="get" >
  #<cfhttpparam type="header" name="accept-encoding" value="deflate;q=0">
  #<cfhttpparam type="header" name="te" value="deflate;q=0">
  #<cfhttpparam name="id" value="5173944631" type="url" />
  #<cfhttpparam name="origin" value="48910"  type="url" />
  #<cfhttpparam name="dest" value="#zip#" type="url"  />
  #<cfhttpparam name="class1" value="#shipclass#" type="url"  />
  #<cfhttpparam name="weight1" value="#tmpweight#" type="url"  />
  #<cfhttpparam name="delnotify" value="X" type="url"  />
  #<cfhttpparam name="hazmat" value="#ormd#" type="url"  />
  #<cfhttpparam name="resdel" value="#residential#" type="url"  />
  #</cfhttp>

  def ship_class
    x = 60
    x
  end
  def check_ormd
    ormd_items = @cart_items.find_all { |item| item.ormd != nil && item.ormd > 0 }
    ormd_items.length
  end
end
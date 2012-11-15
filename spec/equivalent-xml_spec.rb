if defined?(RUBY_ENGINE) and (RUBY_ENGINE == 'ruby') and (RUBY_VERSION >= '1.9')
  require 'simplecov'
  SimpleCov.start
end
$:.push(File.join(File.dirname(__FILE__),'..','lib'))
require 'nokogiri'
require 'equivalent-xml'

describe EquivalentXml do

  it "should consider a document equivalent to itself" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc1.should be_equivalent_to(doc1)
  end

  it "should compare non-XML content based on its string representation" do
    nil.should be_equivalent_to(nil)
    ''.should be_equivalent_to('')
    ''.should be_equivalent_to(nil)
    'foo'.should be_equivalent_to('foo')
    'foo'.should_not be_equivalent_to('bar')
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first order='1'>foo  bar baz</first><second>things</second></doc>")
    doc1.should_not be_equivalent_to(nil)
  end

  it "should ensure that attributes match" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first order='1'>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><first order='2'>foo  bar baz</first><second>things</second></doc>")
    doc1.should_not be_equivalent_to(doc2)

    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first order='1'>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><first order='1'>foo  bar baz</first><second>things</second></doc>")
    doc1.should be_equivalent_to(doc2)
  end

  it "shouldn't care about attribute order" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first order='1' value='quux'>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><first value='quux' order='1'>foo  bar baz</first><second>things</second></doc>")
    doc1.should be_equivalent_to(doc2)
  end

  it "shouldn't care about element order by default" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><second>things</second><first>foo  bar baz</first></doc>")
    doc1.should be_equivalent_to(doc2)
  end

  it "should care about element order if :element_order => true is specified" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><second>things</second><first>foo  bar baz</first></doc>")
    doc1.should_not be_equivalent_to(doc2).respecting_element_order
  end

  it "should ensure nodesets have the same number of elements" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><second>things</second><first>foo  bar baz</first><third/></doc>")
    doc1.should_not be_equivalent_to(doc2)
  end

  it "should ensure namespaces match" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:baz'><first>foo  bar baz</first><second>things</second></doc>")
    doc1.should_not be_equivalent_to(doc2)
  end

  it "should compare namespaces based on URI, not on prefix" do
    doc1 = Nokogiri::XML("<doc xmlns:foo='foo:bar'><foo:first>foo  bar baz</foo:first><foo:second>things</foo:second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns:baz='foo:bar'><baz:first>foo  bar baz</baz:first><baz:second>things</baz:second></doc>")
    doc1.should be_equivalent_to(doc2)
  end

  it "should ignore declared but unused namespaces" do
    doc1 = Nokogiri::XML("<doc xmlns:foo='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc><first>foo  bar baz</first><second>things</second></doc>")
    doc1.should be_equivalent_to(doc2)
  end

  it "should normalize simple whitespace by default" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo bar  baz</first><second>things</second></doc>")
    doc1.should be_equivalent_to(doc2)
  end

  it "shouldn't normalize simple whitespace if :normalize_whitespace => false is specified" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo bar  baz</first><second>things</second></doc>")
    doc1.should_not be_equivalent_to(doc2).with_whitespace_intact
  end

  it "should normalize complex whitespace by default" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML(%{<doc xmlns='foo:bar'>
      <second>things</second>
      <first>
        foo
        bar baz
      </first>
    </doc>})
    doc1.should be_equivalent_to(doc2)
  end

  it "shouldn't normalize complex whitespace if :normalize_whitespace => false is specified" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML(%{<doc xmlns='foo:bar'>
      <second>things</second>
      <first>
        foo
        bar baz
      </first>
    </doc>})
    doc1.should_not be_equivalent_to(doc2).with_whitespace_intact
  end

  it "should ignore leading whitespace #1" do
    doc1 = Nokogiri::XML("<bar><foo /></bar>")
    doc2 = Nokogiri::XML(" <bar><foo /></bar>")
    doc1.should be_equivalent_to(doc2)
  end

  it "should ignore leading whitespace #2" do
    doc1 = Nokogiri::XML("<?xml version='1.0' encoding='utf-8' ?><foo />")
    doc2 = Nokogiri::XML(" <?xml version='1.0' encoding='utf-8' ?><foo />")
    doc1.should be_equivalent_to(doc2)
  end

  it "should ignore comment nodes" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc2 = Nokogiri::XML(%{<doc xmlns='foo:bar'>
      <second>things</second>
      <!-- Comment Node -->
      <first>
        foo
        bar baz
      </first>
    </doc>})
    doc1.should be_equivalent_to(doc2)
  end

  it "should properly handle a mixture of text and element nodes" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><phrase>This phrase <b>has bold text</b> in it.</phrase></doc>")
    doc2 = Nokogiri::XML("<doc xmlns='foo:bar'><phrase>This phrase in <b>has bold text</b> it.</phrase></doc>")
    doc1.should_not be_equivalent_to(doc2)
  end

  it "should properly handle documents passed in as strings" do
    doc1 = "<doc xmlns='foo:bar'><first order='1'>foo  bar baz</first><second>things</second></doc>"
    doc2 = "<doc xmlns='foo:bar'><first order='1'>foo  bar baz</first><second>things</second></doc>"
    doc1.should be_equivalent_to(doc2)

    doc1 = "<doc xmlns='foo:bar'><first order='1'>foo  bar baz</first><second>things</second></doc>"
    doc2 = "<doc xmlns='foo:bar'><first order='1'>foo  bar baz quux</first><second>things</second></doc>"
    doc1.should_not be_equivalent_to(doc2)
  end

  it "should compare nodesets" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc1.root.children.should be_equivalent_to(doc1.root.children)
  end

  it "should compare nodeset with string" do
    doc1 = Nokogiri::XML("<doc xmlns='foo:bar'><first>foo  bar baz</first><second>things</second></doc>")
    doc1.root.children.should be_equivalent_to("<first xmlns='foo:bar'>foo  bar baz</first><second xmlns='foo:bar'>things</second>")
  end

  context "with the :ignore_content_paths option set to a CSS selector" do
    it "ignores the text content of a node that matches the given CSS selector when comparing with #equivalent?" do
      doc1 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>1234</SerialNumber></Device></Devices>")
      doc2 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>5678</SerialNumber></Device></Devices>")

      EquivalentXml.equivalent?(doc1, doc2, :ignore_content => "SerialNumber").should be_true
      EquivalentXml.equivalent?(doc1, doc2, :ignore_content => "Devices>Device>SerialNumber").should be_true

      doc1.should be_equivalent_to(doc2).ignoring_content_of("SerialNumber")
      doc1.should be_equivalent_to(doc2).ignoring_content_of("Devices>Device>SerialNumber")
    end

    it "ignores the text content of a node that matches the given CSS selector when comparing with a matcher" do
      doc1 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>1234</SerialNumber></Device></Devices>")
      doc2 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>5678</SerialNumber></Device></Devices>")

      doc1.should be_equivalent_to(doc2).ignoring_content_of("SerialNumber")
      doc1.should be_equivalent_to(doc2).ignoring_content_of("Devices>Device>SerialNumber")
    end

    it "ignores all children of a node that matches the given selector when comparing for equivalence" do
      doc1 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>1234</SerialNumber></Device></Devices>")
      doc2 = Nokogiri::XML("<Devices><Device><Name>iPad</Name><SerialNumber>5678</SerialNumber></Device></Devices>")

      doc1.should be_equivalent_to(doc2).ignoring_content_of("Device")
    end

    it "still considers the number of elements even if they match the given CSS selector" do
      doc1 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>1234</SerialNumber></Device></Devices>")
      doc2 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>1234</SerialNumber></Device><Device><Name>iPad</Name><SerialNumber>5678</SerialNumber></Device></Devices>")

      doc1.should_not be_equivalent_to(doc2).ignoring_content_of("Device")
    end

    it "still considers attributes on the matched path when comparing for equivalence" do
      doc1 = Nokogiri::XML("<Devices><Device status='owned'><Name>iPhone</Name><SerialNumber>1234</SerialNumber></Device></Devices>")
      doc2 = Nokogiri::XML("<Devices><Device status='rented'><Name>iPhone</Name><SerialNumber>1234</SerialNumber></Device></Devices>")

      doc1.should_not be_equivalent_to(doc2).ignoring_content_of("Device")
    end

    it "ignores all matches of the CSS selector" do
      doc1 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>1001</SerialNumber></Device><Device><Name>iPad</Name><SerialNumber>2001</SerialNumber></Device></Devices>")
      doc2 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>1002</SerialNumber></Device><Device><Name>iPad</Name><SerialNumber>2002</SerialNumber></Device></Devices>")

      doc1.should be_equivalent_to(doc2).ignoring_content_of("SerialNumber")
    end
  end

  context "with the :ignore_content_paths option set to an array of CSS selectors" do
    it "ignores the content of all nodes that match any of the given CSS selectors when comparing for equivalence" do
      doc1 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>1234</SerialNumber><ICCID>AAAA</ICCID></Device></Devices>")
      doc2 = Nokogiri::XML("<Devices><Device><Name>iPhone</Name><SerialNumber>5678</SerialNumber><ICCID>BBBB</ICCID></Device></Devices>")

      doc1.should be_equivalent_to(doc2).ignoring_content_of(["SerialNumber", "ICCID"])
    end
  end
end

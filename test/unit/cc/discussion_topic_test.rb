require 'nokogiri'
require 'minitest/autorun'
require 'test/test_helper'
require 'moodle2cc'

class TestUnitCCDiscussionTopic < MiniTest::Unit::TestCase
  include TestHelper

  def setup
    stub_moodle_backup
    @mod = @backup.course.mods[2] # discussion topic module
  end

  def teardown
    clean_tmp_folder
  end

  def test_it_converts_id
    @mod.id = 567

    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    assert_equal 567, discussion_topic.id
  end

  def test_it_converts_title
    @mod.name = "Announcements"

    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    assert_equal "Announcements", discussion_topic.title
  end

  def test_it_converts_text
    @mod.intro = "<h1>Hello World</h1>"

    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    assert_equal "<h1>Hello World</h1>", discussion_topic.text
  end

  def test_it_converts_posted_at
    @mod.section_mod.added = 1340731824

    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    assert_equal '2012-06-26T17:30:24', discussion_topic.posted_at
  end

  def test_it_converts_position
    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod, 5
    assert_equal 5, discussion_topic.position
  end

  def test_it_converts_type
    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    assert_equal 'topic', discussion_topic.type
  end

  def test_it_has_an_identifier
    @mod.id = 123

    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    assert_equal 'i802fea43604b8e56736e233ae2ca2ee9', discussion_topic.identifier
  end

  def test_it_has_an_identifierref
    @mod.id = 123

    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    assert_equal 'ic2f863a4aeaa551a04dfbea65d6e72bb', discussion_topic.identifierref
  end

  def test_it_create_topic_xml
    @mod.name = "Announcements"
    @mod.intro = "<h1>Hello World</h1>"

    tmp_dir = File.expand_path('../../../tmp', __FILE__)
    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    discussion_topic.create_topic_xml(tmp_dir)
    xml = Nokogiri::XML(File.read(File.join(tmp_dir, "#{discussion_topic.identifier}.xml")))

    assert xml
    assert_equal "http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1 http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imsdt_v1p1.xsd", xml.root.attributes['schemaLocation'].value
    assert_equal "http://www.w3.org/2001/XMLSchema-instance", xml.namespaces['xmlns:xsi']
    assert_equal "http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1", xml.namespaces['xmlns']

    assert_equal 'Announcements', xml.search('title').text
    assert_equal 'text/html', xml.search('text').first.attributes['texttype'].value
    assert_equal '<h1>Hello World</h1>', xml.search('text').text
  end

  def test_it_create_topic_meta_xml
    @mod.name = "Announcements"
    @mod.section_mod.added = 1340731824

    tmp_dir = File.expand_path('../../../tmp', __FILE__)
    discussion_topic = Moodle2CC::CC::DiscussionTopic.new @mod
    discussion_topic.create_topic_meta_xml(tmp_dir)
    xml = Nokogiri::XML(File.read(File.join(tmp_dir, "#{discussion_topic.identifierref}.xml")))

    assert xml
    assert_equal "http://canvas.instructure.com/xsd/cccv1p0 http://canvas.instructure.com/xsd/cccv1p0.xsd", xml.root.attributes['schemaLocation'].value
    assert_equal "http://www.w3.org/2001/XMLSchema-instance", xml.namespaces['xmlns:xsi']
    assert_equal "http://canvas.instructure.com/xsd/cccv1p0", xml.namespaces['xmlns']
    assert_equal discussion_topic.identifierref, xml.xpath('xmlns:topicMeta').first.attributes['identifier'].value

    assert_equal discussion_topic.identifier, xml.search('topic_id').text
    assert_equal 'Announcements', xml.search('title').text
    assert_equal '2012-06-26T17:30:24', xml.search('posted_at').text
    assert_equal '0', xml.search('position').text
    assert_equal 'topic', xml.search('type').text
  end
end

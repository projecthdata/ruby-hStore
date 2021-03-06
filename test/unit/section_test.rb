# Adding the root dir to the load path for Ruby 1.9.2 compatiblilty
$: << File.join(File.dirname(__FILE__), '../..')

require 'test/test_helper'

class SectionTest < HDataTest
  context "A section of an hData Record" do
    # TODO: Clean up the use of fixture_file
    setup do
      @record = Record.create
      @record.extensions.create(:extension_id  => 'http://projecthdata.org/hdata/schemas/2009/06/allergy')
      @record.sections.create(:name => 'Allergies', :path => 'allergies', :extension_id  => 'http://projecthdata.org/hdata/schemas/2009/06/allergy')
      @section = @record.sections.find_by_path('allergies')
      @doc = SectionDocument.new()
      fixture_file = File.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'allergy1.xml'))
      @doc.create_document(fixture_file.read, 'allergy1.xml', 'application/xml')
      fixture_file = File.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'metadata1.xml'))
      ng = Nokogiri::XML(fixture_file)
      @doc.create_metadata_from_xml(ng.root)
      # Rereading the fixture_file because rewind seems to kill JRuby
      fixture_file = File.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'metadata1.xml'))
      @doc.store_metadata(fixture_file)
      @section.section_documents << @doc
    end
    
    should 'return an ATOM feed at the root' do
      get "/records/#{@record.id}/allergies"
      assert last_response.ok?
    end
    
    should 'allow the delete of a section' do
      delete "/records/#{@record.id}/allergies"
      assert_equal 204, last_response.status
      @record.reload
      assert !@record.sections.path_exists?('allergies')
    end
    
    should 'allow the POSTing of a section document' do
      upload_file = Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'allergy1.xml'), 'application/xml')
      post "/records/#{@record.id}/allergies", {:type => 'document', :content => upload_file}
      assert_equal 201, last_response.status
      section = @record.sections.find_by_path('allergies')
      assert_equal 2, section.section_documents.count
      new_section_document_id = last_response.body[-24..-1]
      doc = section.section_documents.detect {|sd| sd.id.to_s == new_section_document_id}
      assert doc
    end
    
    should 'allow the POSTing of a section document and metadata' do
      section_document = Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'allergy1.xml'), 'application/xml')
      metadata = Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'metadata1.xml'), 'application/xml')
      post "/records/#{@record.id}/allergies", {:type => 'document', :content => section_document, :metadata => metadata}
      assert_equal 201, last_response.status
      section = @record.sections.find_by_path('allergies')
      assert_equal 2, section.section_documents.count
      new_section_document_id = last_response.body[-24..-1]
      doc = section.section_documents.detect {|sd| sd.id.to_s == new_section_document_id}
      assert doc
      assert_equal 'Random Title', doc.title
      assert_equal 'RandomDocumentId', doc.document_id
    end

  end
end

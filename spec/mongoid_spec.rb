require 'spec_helper'
require 'carrierwave_direct/mongoid'

describe CarrierWaveDirect::Mongoid do
  class MyDocument
    include Mongoid::Document
    mount_uploader :video, DirectUploader
  end

  subject { MyDocument.new }

  describe "#key" do
    it "should be accessible" do
      MyDocument.new(:key => "some key").key.should == "some key"
    end
  end
end

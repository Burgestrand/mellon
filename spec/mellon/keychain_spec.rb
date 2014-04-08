describe Mellon::Keychain do
  around do |example|
    FileUtils.cp(keychain_path, temporary_keychain_path)
    example.run
    FileUtils.rm(temporary_keychain_path)
  end

  let(:temporary_keychain_path) do
    File.expand_path("../temporary_keychain.keychain", __dir__)
  end

  let(:keychain_path) do
    File.expand_path("../keychain.keychain", __dir__)
  end

  subject(:keychain) do
    Mellon::Keychain.new(temporary_keychain_path)
  end

  specify "#name" do
    keychain.name.should eq "temporary_keychain"
  end

  specify "#path" do
    keychain.path.should eq temporary_keychain_path
  end

  describe "#[key]" do
    it "reads simple entries" do
      keychain["simple"].should eq "Simple note"
    end

    it "reads encoded entries" do
      keychain["encoded"].should eq "Encoded\nnote"
    end

    it "reads plist entries" do
      keychain["plist"].should eq "Plist note."
    end

    it "reads empty entries" do
      keychain["empty"].should eq ""
    end

    it "returns nil when there is no entry with the given name" do
      keychain["nonexisting note"].should be_nil
    end
  end

  describe "#[]=" do
    it "can create a new note" do
      keychain["new note"].should be_nil
      keychain["new note"] = "This is new data"
      keychain["new note"].should eq "This is new data"
    end

    it "can write data to an existing note" do
      keychain["existing"].should eq "Existing note."
      keychain["existing"] = "This is new"
      keychain["existing"].should eq "This is new"
    end

    it "can delete an existing note" do
      keychain["doomed"].should_not be_nil
      keychain["doomed"] = nil
      keychain["doomed"].should be_nil
    end
  end
end

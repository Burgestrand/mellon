describe Mellon::Store do
  subject(:store) { Mellon::Store.new(project_name, keychain: keychain) }
  let(:project_name) { "yaml store" }
  let(:keychain) { Mellon::Keychain.new(keychain_path) }

  describe "#initialize" do
    it "requires a project name" do
      expect { Mellon::Store.new }.to raise_error(ArgumentError)
    end

    it "finds and uses the keychain containing the project name by default" do
      Mellon::Keychain.should_receive(:search).with(project_name).and_return(keychain)
      Mellon::Store.new(project_name).keychain.should eq keychain
    end

    it "uses the default keychain is no keychain contains the project name" do
      keychain = double
      Mellon::Keychain.should_receive(:search).with(project_name).and_return(nil)
      Mellon::Keychain.should_receive(:default).and_return(keychain)
      Mellon::Store.new(project_name).keychain.should eq keychain
    end

    it "accepts specifying the keychain by name" do
      keychain = double
      Mellon::Keychain.should_receive(:find).with("projects").and_return(keychain)
      store = Mellon::Store.new(project_name, keychain: "projects")
      store.keychain.should eq keychain
    end

    it "accepts specifying the keychain object" do
      store = Mellon::Store.new(project_name, keychain: keychain)
      store.keychain.should eq keychain
    end

    it "allows setting the serializer" do
      require "json"
      store = Mellon::Store.new("json store", keychain: keychain, serializer: JSON)
      store["some value"].should eq "This is some json value"
      store["some value"] = "New value"
      store["some value"].should eq "New value"
    end
  end

  describe "#[]" do
    it "returns the value for key inside the store" do
      store["some value"].should eq "This is some yaml value"
    end

    it "returns nil if store entry does not exist" do
      store = Mellon::Store.new("missing project", keychain: keychain)
      store["some value"].should be_nil
    end

    it "returns nil if keychain item is empty" do
      store = Mellon::Store.new("empty", keychain: keychain)
      store["some value"].should be_nil
      store["some value"] = "New value"
      store["some value"].should eq "New value"
    end
  end

  describe "#[]=" do
    it "assigns an existing value for key inside the store" do
      store["some value"].should eq "This is some yaml value"
      store["some value"] = "This is a new value"
      store["some value"].should eq "This is a new value"
    end

    it "creates the store entry if it does not exist" do
      store = Mellon::Store.new("missing project", keychain: keychain)
      store["some value"].should be_nil
      store["some value"] = "That value"
      store["some value"].should eq "That value"
    end
  end

  specify "#fetch" do
    store.fetch("some value").should eq "This is some yaml value"
    store.fetch("missing value", "default").should eq "default"
    store.fetch("missing value") { "default" }.should eq "default"

    expect { store.fetch("missing value") }.to raise_error(KeyError)
  end
end

describe Mellon::Store do
  subject(:store) { Mellon::Store.new(project_name, keychain: keychain) }
  let(:project_name) { "yaml store" }
  let(:keychain) { Mellon::Keychain.new(keychain_path) }

  describe "#initialize" do
    it "requires a project name" do
      expect { Mellon::Store.new }.to raise_error(ArgumentError)
    end

    it "finds and uses the keychain containing the project name by default" do
      expect(Mellon::Keychain).to receive(:search).with(project_name).and_return(keychain)
      expect(Mellon::Store.new(project_name).keychain).to eq keychain
    end

    it "uses the default keychain is no keychain contains the project name" do
      keychain = double
      expect(Mellon::Keychain).to receive(:search).with(project_name).and_return(nil)
      expect(Mellon::Keychain).to receive(:default).and_return(keychain)
      expect(Mellon::Store.new(project_name).keychain).to eq keychain
    end

    it "accepts specifying the keychain by name" do
      keychain = double
      expect(Mellon::Keychain).to receive(:find).with("projects").and_return(keychain)
      store = Mellon::Store.new(project_name, keychain: "projects")
      expect(store.keychain).to eq keychain
    end

    it "accepts specifying the keychain object" do
      store = Mellon::Store.new(project_name, keychain: keychain)
      expect(store.keychain).to eq keychain
    end

    it "allows setting the serializer" do
      require "json"
      store = Mellon::Store.new("json store", keychain: keychain, serializer: JSON)
      expect(store["some value"]).to eq "This is some json value"
      store["some value"] = "New value"
      expect(store["some value"]).to eq "New value"
    end
  end

  describe "#[]" do
    it "returns the value for key inside the store" do
      expect(store["some value"]).to eq "This is some yaml value"
    end

    it "returns nil if store entry does not exist" do
      store = Mellon::Store.new("missing project", keychain: keychain)
      expect(store["some value"]).to be_nil
    end

    it "returns nil if keychain item is empty" do
      store = Mellon::Store.new("empty", keychain: keychain)
      expect(store["some value"]).to be_nil
      store["some value"] = "New value"
      expect(store["some value"]).to eq "New value"
    end
  end

  describe "#[]=" do
    it "assigns an existing value for key inside the store" do
      expect(store["some value"]).to eq "This is some yaml value"
      store["some value"] = "This is a new value"
      expect(store["some value"]).to eq "This is a new value"
    end

    it "creates the store entry if it does not exist" do
      store = Mellon::Store.new("missing project", keychain: keychain)
      expect(store["some value"]).to be_nil
      store["some value"] = "That value"
      expect(store["some value"]).to eq "That value"
    end
  end

  describe "#to_h" do
    it "returns a hash with all keys contained" do
      store["new value"] = "This is new value"
      expect(store.to_h).to eq({
        "some value" => "This is some yaml value",
        "new value"  => "This is new value"
      })
    end
  end

  specify "#fetch" do
    expect(store.fetch("some value")).to eq "This is some yaml value"
    expect(store.fetch("missing value", "default")).to eq "default"
    expect(store.fetch("missing value") { "default" }).to eq "default"

    expect { store.fetch("missing value") }.to raise_error(KeyError)
  end
end

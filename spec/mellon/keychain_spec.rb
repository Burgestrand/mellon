describe Mellon::Keychain do
  subject(:keychain) do
    Mellon::Keychain.new(keychain_path)
  end

  describe ".search" do
    it "returns the first keychain that contains the requested entry" do
      stub_command "security find-generic-password -l booboom", stdout: <<-STDOUT
keychain: "/Users/dev/Library/Keychains/projects.keychain"
class: "genp"
attributes:
    0x00000007 <blob>="booboom"
    0x00000008 <blob>=<NULL>
    "acct"<blob>=<NULL>
    "cdat"<timedate>=0x32303135303132333037343035395A00  "20150123074059Z\000"
    "crtr"<uint32>=<NULL>
    "cusi"<sint32>=<NULL>
    "desc"<blob>="secure note"
    "gena"<blob>=<NULL>
    "icmt"<blob>=<NULL>
    "invi"<sint32>=<NULL>
    "mdat"<timedate>=0x32303135303132333037343035395A00  "20150123074059Z\000"
    "nega"<sint32>=<NULL>
    "prot"<blob>=<NULL>
    "scrp"<sint32>=<NULL>
    "svce"<blob>="booboom"
    "type"<uint32>="note"
      STDOUT

      keychain = Mellon::Keychain.search "booboom"
      expect(keychain.path).to eq "/Users/dev/Library/Keychains/projects.keychain"
      expect(keychain.name).to eq "projects"
    end

    it "returns nil if the entry is missing" do
      stub_command "security find-generic-password -l booboom", error: true, stderr: <<-STDERR
security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain.
      STDERR

      keychain = Mellon::Keychain.search "booboom"
      expect(keychain).to eq nil
    end
  end

  describe ".find" do
    before do
      stub_command "security list-keychains", stdout: <<-STDOUT
    "/Users/dev/Library/Keychains/login.keychain"
    "/Users/dev/Library/Keychains/projects.keychain"
    "/Users/dev/Library/Keychains/developer.keychain"
    "/Library/Keychains/System.keychain"
      STDOUT
    end

    it "finds a keychain matching the given name" do
      keychain = Mellon::Keychain.find("dev")
      expect(keychain.name).to eq "developer"
      expect(keychain.path).to eq "/Users/dev/Library/Keychains/developer.keychain"
    end

    it "raises an error if no keychain was found" do
      expect { Mellon::Keychain.find("bar") }.to raise_error(KeyError, /Could not find keychain/)
    end
  end

  specify ".default" do
    stub_command "security default-keychain", stdout: <<-STDOUT
      "/Users/dev/Library/Keychains/login.keychain"
    STDOUT

    default = Mellon::Keychain.default
    expect(default.path).to eq "/Users/dev/Library/Keychains/login.keychain"
    expect(default.name).to eq "login"
  end

  specify "#name" do
    expect(keychain.name).to eq "temporary_keychain"
  end

  specify "#path" do
    expect(keychain.path).to eq keychain_path
  end

  specify "keychain can be stored in hash" do
    hash = {}
    hash[keychain] = "some value"
    expect(hash[Mellon::Keychain.new(keychain.path)]).to eq "some value"
  end

  describe "#==" do
    it "is equal to another keychain with same path" do
      expect(keychain).to eq Mellon::Keychain.new(keychain.path)
    end

    it "is not equal to any other object" do
      expect(keychain).to_not eq({})
    end
  end

  describe "#initialize" do
    it "raises an error if keychain does not exist" do
      expect { Mellon::Keychain.new("missing.keychain") }.to raise_error(Mellon::Error, /missing.keychain/)
    end
  end

  describe "#keys" do
    it "lists all keys available in the keychain" do
      expect(keychain.keys).to contain_exactly("simple", "existing", "encoded", "plist", "empty", "doomed", "json store", "yaml store")
    end
  end

  describe "#fetch" do
    it "delegates (and as such, behaves equally) to #[]" do
      expect(keychain).to receive(:[]).with("simple").and_call_original
      expect(keychain.fetch("simple")).to eq "Simple note"
    end

    describe "behaves like Hash#fetch" do
      specify "when key exists" do
        expect(keychain.fetch("simple", nil)).to eq "Simple note"
        expect(keychain.fetch("simple", "default value")).to eq "Simple note"
        expect(keychain.fetch("simple", "default value") { "block value" }).to eq "Simple note"
        expect(keychain.fetch("simple") { "block value" }).to eq "Simple note"

        expect(keychain.fetch("simple")).to eq "Simple note"
      end

      specify "when key does not exist" do
        expect(keychain.fetch("missing", nil)).to eq nil
        expect(keychain.fetch("missing", "default value")).to eq "default value"
        expect(keychain.fetch("missing", "default value") { "block value" }).to eq "block value"
        expect(keychain.fetch("missing") { "block value" }).to eq "block value"

        expect { keychain.fetch("missing") }.to raise_error(KeyError)
      end
    end
  end

  describe "#[key]" do
    it "reads simple entries" do
      expect(keychain["simple"]).to eq "Simple note"
    end

    it "reads encoded entries" do
      expect(keychain["encoded"]).to eq "Encoded\nnote"
    end

    it "reads plist entries" do
      expect(keychain["plist"]).to eq "Plist note."
    end

    it "reads empty entries" do
      expect(keychain["empty"]).to eq ""
    end

    it "returns nil when there is no entry with the given name" do
      expect(keychain["nonexisting note"]).to be_nil
    end
  end

  describe "#[]=" do
    it "can create a new note" do
      expect(keychain["new note"]).to be_nil
      keychain["new note"] = "This is new data"
      expect(keychain["new note"]).to eq "This is new data"
    end

    it "can write data to an existing note" do
      expect(keychain["existing"]).to eq "Existing note."
      keychain["existing"] = "This is new"
      expect(keychain["existing"]).to eq "This is new"
    end

    it "can delete an existing note" do
      expect(keychain["doomed"]).to_not be_nil
      keychain["doomed"] = nil
      expect(keychain["doomed"]).to be_nil
    end
  end
end

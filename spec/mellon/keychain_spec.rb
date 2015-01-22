describe Mellon::Keychain do
  subject(:keychain) do
    Mellon::Keychain.new(keychain_path)
  end

  specify "#name" do
    keychain.name.should eq "temporary_keychain"
  end

  specify "#path" do
    keychain.path.should eq keychain_path
  end

  specify "keychain can be stored in hash" do
    hash = {}
    hash[keychain] = "some value"
    hash[Mellon::Keychain.new(keychain.path)].should eq "some value"
  end

  describe "#==" do
    it "is equal to another keychain with same path" do
      keychain.should eq Mellon::Keychain.new(keychain.path)
    end

    it "is not equal to any other object" do
      keychain.should_not eq({})
    end
  end

  describe "#initialize" do
    it "raises an error if keychain does not exist" do
      expect { Mellon::Keychain.new("missing.keychain") }.to raise_error(Mellon::Error, /missing.keychain/)
    end
  end

  describe "#keys" do
    it "lists all keys available in the keychain" do
      keychain.keys.should =~ ["simple", "existing", "encoded", "plist", "empty", "doomed", "json store", "yaml store"]
    end
  end

  describe "#fetch" do
    it "delegates (and as such, behaves equally) to #[]" do
      keychain.should_receive(:[]).with("simple").and_call_original
      keychain.fetch("simple").should eq "Simple note"
    end

    describe "behaves like Hash#fetch" do
      specify "when key exists" do
        keychain.fetch("simple", nil).should eq "Simple note"
        keychain.fetch("simple", "default value").should eq "Simple note"
        keychain.fetch("simple", "default value") { "block value" }.should eq "Simple note"
        keychain.fetch("simple") { "block value" }.should eq "Simple note"

        keychain.fetch("simple").should eq "Simple note"
      end

      specify "when key does not exist" do
        keychain.fetch("missing", nil).should eq nil
        keychain.fetch("missing", "default value").should eq "default value"
        keychain.fetch("missing", "default value") { "block value" }.should eq "block value"
        keychain.fetch("missing") { "block value" }.should eq "block value"

        expect { keychain.fetch("missing") }.to raise_error(KeyError)
      end
    end
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

    it "raises an error when command exits for a reason other than key missing" do
      error = Mellon::CommandError.new(<<-ERROR)
security find-generic-password -g -l unreadable /Users/dev/Projects/mellon/spec/temporary_keychain.keychain
  security: SecKeychainItemCopyAccess: In dark wake, no UI possible
ERROR
      Mellon::Utils.should_receive(:sh).and_raise(error)
      expect { keychain["simple"] }.to raise_error(Mellon::CommandError, /dark wake/)
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

require "test_helper"

module Gemdiff
  class OutdatedGemTest < MiniTest::Spec
    describe "#missing_versions?" do
      it "returns true" do
        assert OutdatedGem.new("x").missing_versions?
      end

      it "returns false" do
        refute OutdatedGem.new("x", "1", "2").missing_versions?
      end
    end

    describe "#compare_url" do
      it "returns compare url" do
        outdated_gem = OutdatedGem.new("x", "1.0", "2.0")
        outdated_gem.stubs repo: "http://github.com/x/x"
        assert_equal "http://github.com/x/x/compare/v1.0...v2.0", outdated_gem.compare_url
      end

      it "returns compare url with no v for exceptions" do
        outdated_gem = OutdatedGem.new("haml", "4.0.0", "4.1.0")
        outdated_gem.stubs repo: "http://github.com/haml/haml"
        assert_equal "http://github.com/haml/haml/compare/4.0.0...4.1.0", outdated_gem.compare_url
      end

      it "returns compare url with branch name for new version" do
        outdated_gem = OutdatedGem.new("x", "4.0.0", "master")
        outdated_gem.stubs repo: "http://github.com/x/x"
        assert_equal "http://github.com/x/x/compare/v4.0.0...master", outdated_gem.compare_url
      end
    end

    describe "#releases_url" do
      it "returns releases url" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.stubs repo: "http://github.com/x/x"
        assert_equal "http://github.com/x/x/releases", outdated_gem.releases_url
      end
    end

    describe "#commits_url" do
      it "returns commits url" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.stubs repo: "http://github.com/x/x"
        assert_equal "http://github.com/x/x/commits/master", outdated_gem.commits_url
      end
    end

    describe "#compare_message" do
      it "returns compare message" do
        outdated_gem = OutdatedGem.new("x", "1", "2")
        outdated_gem.stubs repo: "http://github.com/x/x"
        assert_equal "x: 2 > 1", outdated_gem.compare_message
      end
    end

    describe "#load_bundle_versions" do
      it "returns false if not found" do
        mock_inspector = mock { stubs :get }
        BundleInspector.stubs new: mock_inspector
        refute OutdatedGem.new("x").load_bundle_versions
      end

      it "sets versions from gem in bundle" do
        mock_outdated_gem = OutdatedGem.new("y", "1.2.3", "2.3.4")
        mock_inspector = mock { stubs get: mock_outdated_gem }
        BundleInspector.stubs new: mock_inspector
        outdated_gem = OutdatedGem.new("y")
        assert outdated_gem.load_bundle_versions
        assert_equal "1.2.3", outdated_gem.old_version
        assert_equal "2.3.4", outdated_gem.new_version
      end
    end

    describe "#set_versions" do
      it "sets nil versions" do
        outdated_gem = OutdatedGem.new("x", "1", "2")
        outdated_gem.set_versions nil, nil
        assert_nil outdated_gem.old_version
        assert_nil outdated_gem.new_version
      end

      it "sets old, new versions" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.set_versions "1.2.34", "2.34.56"
        assert_equal "1.2.34", outdated_gem.old_version
        assert_equal "2.34.56", outdated_gem.new_version
      end

      it "swaps versions in the wrong order" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.set_versions "2.34.56", "1.2.34"
        assert_equal "1.2.34", outdated_gem.old_version
        assert_equal "2.34.56", outdated_gem.new_version
      end

      it "swaps versions over 10 in the wrong order" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.set_versions "1.10.0", "1.9.3"
        assert_equal "1.9.3", outdated_gem.old_version
        assert_equal "1.10.0", outdated_gem.new_version
      end

      it "swaps versions with master" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.set_versions "master", "1.9.3"
        assert_equal "1.9.3", outdated_gem.old_version
        assert_equal "master", outdated_gem.new_version
      end
    end

    describe "#master" do
      it "opens master commits url" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.stubs repo: "http://github.com/x/x"
        outdated_gem.expects(:open_url).with("http://github.com/x/x/commits/master")
        outdated_gem.master
      end
    end

    describe "#releases" do
      it "opens releases url" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.stubs repo: "http://github.com/x/x"
        outdated_gem.expects(:open_url).with("http://github.com/x/x/releases")
        outdated_gem.releases
      end
    end

    describe "#compare" do
      it "opens compare url" do
        outdated_gem = OutdatedGem.new("x", "1.2.3", "2.3.4")
        outdated_gem.stubs repo: "http://github.com/x/x"
        outdated_gem.expects(:open_url).with("http://github.com/x/x/compare/v1.2.3...v2.3.4")
        outdated_gem.compare
      end
    end

    describe "#open" do
      it "opens repo url" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.stubs repo: "http://github.com/x/x"
        outdated_gem.expects(:open_url).with("http://github.com/x/x")
        outdated_gem.open
      end

      it "outputs the url if no browser command is found" do
        outdated_gem = OutdatedGem.new("x")
        outdated_gem.stubs repo: "http://github.com/x/x"

        Launchy.stubs(:open).raises(Launchy::CommandNotFoundError)
        $stdout.expects(:puts).with("http://github.com/x/x")
        outdated_gem.open
      end
    end
  end
end

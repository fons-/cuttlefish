require "spec_helper"

describe Filters::Dkim do
  let(:mail) do
    Mail.new do
      from 'Contact <contact@foo.com>'
      text_part do
        body 'An email with some text and headers'
      end
    end
  end
  let(:filter) {
    Filters::Dkim.new(
      enabled: false,
      domain: "foo.com",
      key: OpenSSL::PKey::RSA.new(2048),
      sender_email: "sender@cuttlefish.oaf.org.au"
    )
  }

  describe "#data" do
    context "dkim is disabled" do
      it { filter.filter_mail(mail).header["DKIM-Signature"].should be_nil }
      it {
        filter.filter_mail(mail).sender.should == "sender@cuttlefish.oaf.org.au"
      }
    end

    context "dkim is enabled" do
      before(:each) { filter.enabled = true }

      context "email from dkim domain" do
        it {
          # Signature is different every time (because of I assume a random salt). So, we're just
          # going to test for the presence of the header
          filter.filter_mail(mail).header["DKIM-Signature"].should_not be_nil
        }
        it { filter.filter_mail(mail).sender.should be_nil}
      end

      context "email from a different domain" do
        before(:each) { mail.from = "Contact <contact@bar.com>" }
        it { filter.filter_mail(mail).header["DKIM-Signature"].should be_nil }
        it { filter.filter_mail(mail).sender.should == "sender@cuttlefish.oaf.org.au"}

        context "and sender is in correct domain" do
          before(:each) { mail.sender = "Contact <contact@foo.com>"}
          it { filter.filter_mail(mail).header["DKIM-Signature"].should_not be_nil }
          it { filter.filter_mail(mail).sender.should == "contact@foo.com"}
        end

        context "and sender is in wrong domain" do
          before(:each) { mail.sender = "Contact <contact@bibble.com>"}
          it { filter.filter_mail(mail).header["DKIM-Signature"].should be_nil }
          it { filter.filter_mail(mail).sender.should == "sender@cuttlefish.oaf.org.au"}
        end
      end
    end
  end
end

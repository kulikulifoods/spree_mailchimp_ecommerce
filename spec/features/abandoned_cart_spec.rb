require "spec_helper"

feature "Abandoned Cart", :js do
  let!(:product)         { create(:product, name: "spree_product") }
  let!(:variant)         { create(:variant, product: product) }
  let!(:state)           { create(:state, id: 2, name: "New York", abbr: "NY", country: country_us) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:country_us)      { create(:country, :country_us) }

  before do
    variant.stock_items.first.update(count_on_hand: 10)
    allow(SpreeMailchimpEcommerce).to receive(:configuration).and_return(SpreeMailchimpEcommerce::Configuration.new)
  end

  scenario "For a guest user" do
    add_product_to_cart
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to_not have_been_enqueued
    expect(current_path).to eq("/checkout/registration")

    fill_in "order_email", with: "spree@example.com"
    click_on "Continue"
    expect(current_path).to eq("/checkout/address")

    fill_in_checkout_address
    expect(current_path).to eq("/checkout/delivery")

    click_on "Save and Continue"
    expect(current_path).to eq("/checkout/payment")
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to have_been_enqueued.exactly(:once)
  end

  scenario "For an existing user" do
    create(:user, email: "spree@example.com", password: "Spree123", password_confirmation: "Spree123")

    add_product_to_cart
    expect(current_path).to eq("/checkout/registration")
    click_on "Login as Existing Customer"
    login
    expect(current_path).to eq("/checkout/address")

    fill_in_checkout_address
    expect(current_path).to eq("/checkout/delivery")

    click_on "Save and Continue"
    expect(current_path).to eq("/checkout/payment")
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to have_been_enqueued.exactly(:once)
  end

  scenario "For a signed in user" do
    create(:user, email: "spree@example.com", password: "Spree123", password_confirmation: "Spree123")
    visit "/login"
    login

    add_product_to_cart
    expect(current_path).to eq("/checkout/address")

    fill_in_checkout_address
    expect(current_path).to eq("/checkout/delivery")

    click_on "Save and Continue"
    expect(current_path).to eq("/checkout/payment")
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to have_been_enqueued.exactly(:once)
  end

  scenario "For a signed up user" do
    add_product_to_cart
    expect(current_path).to eq("/checkout/registration")

    fill_in "spree_user_email", with: "spree@example.com"
    fill_in "spree_user_password", with: "Spree123"
    fill_in "spree_user_password_confirmation", with: "Spree123"
    click_on "Create"
    expect(current_path).to eq("/checkout/address")

    fill_in_checkout_address
    expect(current_path).to eq("/checkout/delivery")

    click_on "Save and Continue"
    expect(current_path).to eq("/checkout/payment")
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to have_been_enqueued.exactly(:once)
  end
end

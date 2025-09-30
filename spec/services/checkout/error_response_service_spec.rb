# frozen_string_literal: true

RSpec.describe Checkout::ErrorResponseService do
  let(:controller) { double('Controller') }
  let(:cart) { create(:cart, :with_items) }
  let(:form) { CheckoutForm.new }

  before do
    allow(controller).to receive(:redirect_to)
    allow(controller).to receive(:render)
    allow(controller).to receive(:flash).and_return(double(now: {}))
    allow(controller).to receive(:instance_variable_set)
    allow(controller).to receive(:root_path).and_return('/')
  end

  describe '.call' do
    subject(:call_service) do
      described_class.call(
        controller: controller,
        result: result,
        cart: cart,
        form: form
      )
    end

    context 'when result contains cart empty error' do
      let(:result) do
        BaseResult.new(
          success: false,
          errors: [ I18n.t('checkout.cart_empty'), 'Another error' ],
          error_type: :validation
        )
      end

      it 'redirects to homepage with alert' do
        expect(controller).to receive(:redirect_to).with(
          '/',
          alert: "#{I18n.t('checkout.cart_empty')}, Another error"
        )
        call_service
      end
    end

    context 'when result has validation error type' do
      let(:result) do
        BaseResult.new(
          success: false,
          errors: [ 'Email is required' ],
          error_type: :validation
        )
      end

      before do
        allow(Checkout::CartValidationService).to receive(:call).with(cart).and_return(
          BaseResult.new(success: true)
        )
      end

      it 'sets instance variables for rendering' do
        expect(controller).to receive(:instance_variable_set).with(:@cart, cart)
        expect(controller).to receive(:instance_variable_set).with(:@checkout_form, form)
        call_service
      end

      it 'sets flash alert and renders new template' do
        flash_now = {}
        allow(controller).to receive(:flash).and_return(double(now: flash_now))

        expect(controller).to receive(:render).with(:new, status: :unprocessable_content)
        call_service

        expect(flash_now[:alert]).to eq('Email is required')
      end

      context 'when cart becomes invalid' do
        before do
          allow(Checkout::CartValidationService).to receive(:call).with(cart).and_return(
            BaseResult.new(success: false, errors: [ I18n.t('checkout.cart_empty') ])
          )
        end

        it 'redirects to homepage instead of rendering' do
          expect(controller).to receive(:redirect_to).with('/', alert: I18n.t('checkout.cart_empty'))
          expect(controller).not_to receive(:render)
          call_service
        end
      end
    end

    context 'when result has service error type' do
      let(:result) do
        BaseResult.new(
          success: false,
          errors: [ 'Payment processing failed' ],
          error_type: :service
        )
      end

      before do
        allow(Checkout::CartValidationService).to receive(:call).with(cart).and_return(
          BaseResult.new(success: true)
        )
      end

      it 'handles service errors similar to validation errors' do
        flash_now = {}
        allow(controller).to receive(:flash).and_return(double(now: flash_now))

        expect(controller).to receive(:instance_variable_set).with(:@cart, cart)
        expect(controller).to receive(:instance_variable_set).with(:@checkout_form, form)
        expect(controller).to receive(:render).with(:new, status: :unprocessable_content)

        call_service
        expect(flash_now[:alert]).to eq('Payment processing failed')
      end

      context 'when errors are nil' do
        let(:result) do
          BaseResult.new(
            success: false,
            errors: nil,
            error_type: :service
          )
        end

        it 'uses default error message' do
          flash_now = {}
          allow(controller).to receive(:flash).and_return(double(now: flash_now))

          call_service
          expect(flash_now[:alert]).to eq(I18n.t('errors.something_went_wrong'))
        end
      end
    end

    context 'when result has no error type (generic error)' do
      let(:result) do
        BaseResult.new(
          success: false,
          errors: [ 'Unknown error' ],
          error_type: nil
        )
      end

      before do
        allow(Checkout::CartValidationService).to receive(:call).with(cart).and_return(
          BaseResult.new(success: true)
        )
      end

      it 'handles generic errors the same as service errors' do
        flash_now = {}
        allow(controller).to receive(:flash).and_return(double(now: flash_now))

        expect(controller).to receive(:render).with(:new, status: :unprocessable_content)
        call_service

        expect(flash_now[:alert]).to eq('Unknown error')
      end
    end
  end
end

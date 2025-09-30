# frozen_string_literal: true

RSpec.describe FormFieldComponent, type: :component do
  include ViewComponent::TestHelpers
  let(:form_object) { double('form', object: user) }
  let(:user) { double('user', errors: errors) }
  let(:errors) { double('errors', '[]' => field_errors, any?: has_errors) }
  let(:field_errors) { [] }
  let(:has_errors) { false }

  before do
    allow(form_object).to receive(:text_field).and_return('<input type="text" />'.html_safe)
    allow(form_object).to receive(:email_field).and_return('<input type="email" />'.html_safe)
    allow(form_object).to receive(:password_field).and_return('<input type="password" />'.html_safe)
    allow(form_object).to receive(:text_area).and_return('<textarea></textarea>'.html_safe)
    allow(form_object).to receive(:telephone_field).and_return('<input type="tel" />'.html_safe)
    allow(form_object).to receive(:radio_button).and_return('<input type="radio" />'.html_safe)
    allow(form_object).to receive(:label).and_return('<label></label>'.html_safe)
    allow(form_object).to receive(:object_name).and_return('user')
    allow(user).to receive(:name).and_return('John Doe')
  end

  describe '#initialize' do
    it 'sets default values correctly' do
      component = FormFieldComponent.new(form: form_object, field: :name)

      aggregate_failures do
        expect(component.form).to eq(form_object)
        expect(component.field_name).to eq(:name)
        expect(component.field_type).to eq(:text)
        expect(component.required).to be_falsey
        expect(component.placeholder).to be_nil
        expect(component.validation_rules).to be_nil
        expect(component.options).to eq({})
      end
    end

    it 'accepts custom parameters' do
      component = FormFieldComponent.new(
        form: form_object,
        field: :email,
        type: :email,
        required: true,
        placeholder: 'Enter email',
        validation_rules: 'email',
        options: { helper_text: 'Help text' }
      )

      expect(component.field_name).to eq(:email)
      expect(component.field_type).to eq(:email)
      expect(component.required).to be_truthy
      expect(component.placeholder).to eq('Enter email')
      expect(component.validation_rules).to eq('email')
      expect(component.options[:helper_text]).to eq('Help text')
    end
  end

  describe '#field_id' do
    it 'generates correct field ID' do
      component = FormFieldComponent.new(form: form_object, field: :name)
      expect(component.field_id).to eq('user_name')
    end
  end

  describe '#has_errors?' do
    context 'when field has errors' do
      let(:field_errors) { [ 'is required' ] }
      let(:has_errors) { true }

      it 'returns true' do
        component = FormFieldComponent.new(form: form_object, field: :name)
        expect(component.has_errors?).to be_truthy
      end
    end

    context 'when field has no errors' do
      it 'returns false' do
        component = FormFieldComponent.new(form: form_object, field: :name)
        expect(component.has_errors?).to be_falsey
      end
    end
  end

  describe '#container_classes' do
    it 'includes base form-field class' do
      component = FormFieldComponent.new(form: form_object, field: :name)
      expect(component.container_classes).to include('form-field')
    end

    it 'includes required class when field is required' do
      component = FormFieldComponent.new(form: form_object, field: :name, required: true)
      expect(component.container_classes).to include('form-field--required')
    end

    context 'when field has errors' do
      let(:field_errors) { [ 'is required' ] }
      let(:has_errors) { true }

      it 'includes error class' do
        component = FormFieldComponent.new(form: form_object, field: :name)
        expect(component.container_classes).to include('form-field--error')
      end
    end


    it 'returns full width for submit buttons' do
      component = FormFieldComponent.new(form: form_object, field: :submit, type: :submit)
      expect(component.container_classes).to eq('w-full')
    end
  end

  describe '#input_field_classes' do
    it 'includes base input classes' do
      component = FormFieldComponent.new(form: form_object, field: :name)
      classes = component.input_field_classes
      expect(classes).to include('text-base')
      expect(classes).to include('bg-transparent')
    end

    it 'includes field-specific classes for text fields' do
      component = FormFieldComponent.new(form: form_object, field: :name)
      classes = component.input_field_classes
      expect(classes).to include('w-full')
      expect(classes).to include('pl-10')
    end


    it 'includes field-specific classes for phone fields (tel normalization)' do
      component = FormFieldComponent.new(form: form_object, field: :phone, type: :phone)
      classes = component.input_field_classes
      expect(classes).to include('border-l-0')
      expect(classes).to include('pl-4')
    end

    it 'includes field-specific classes for tel fields' do
      component = FormFieldComponent.new(form: form_object, field: :phone, type: :tel)
      classes = component.input_field_classes
      expect(classes).to include('border-l-0')
      expect(classes).to include('pl-4')
    end

    context 'when field has errors' do
      let(:field_errors) { [ 'is required' ] }
      let(:has_errors) { true }

      it 'includes error classes' do
        component = FormFieldComponent.new(form: form_object, field: :name)
        classes = component.input_field_classes
        expect(classes).to include('border-red-500')
      end
    end
  end

  describe '#show_counter?' do
    it 'returns true for textarea with show_counter option' do
      component = FormFieldComponent.new(
        form: form_object,
        field: :description,
        type: :textarea,
        options: { show_counter: true }
      )
      expect(component.show_counter?).to be_truthy
    end

    it 'returns false for non-textarea fields' do
      component = FormFieldComponent.new(
        form: form_object,
        field: :name,
        options: { show_counter: true }
      )
      expect(component.show_counter?).to be_falsey
    end

    it 'returns false when show_counter option is not set' do
      component = FormFieldComponent.new(form: form_object, field: :description, type: :textarea)
      expect(component.show_counter?).to be_falsey
    end
  end

  describe '#phone_prefix' do
    it 'returns default Lebanon prefix' do
      component = FormFieldComponent.new(form: form_object, field: :phone)
      expect(component.phone_prefix).to eq('+961')
    end

    it 'returns custom prefix when provided' do
      component = FormFieldComponent.new(
        form: form_object,
        field: :phone,
        options: { phone_prefix: '+1' }
      )
      expect(component.phone_prefix).to eq('+1')
    end
  end

  describe '#aria_describedby' do
    context 'when field has errors' do
      let(:field_errors) { [ 'is required' ] }
      let(:has_errors) { true }

      it 'includes error ID' do
        component = FormFieldComponent.new(form: form_object, field: :name)
        expect(component.aria_describedby).to include('user_name_error')
      end
    end

    it 'includes help ID when helper text is provided' do
      component = FormFieldComponent.new(
        form: form_object,
        field: :name,
        options: { helper_text: 'Help text' }
      )
      expect(component.aria_describedby).to include('user_name_help')
    end

    it 'includes counter ID when show_counter is enabled' do
      component = FormFieldComponent.new(
        form: form_object,
        field: :description,
        type: :textarea,
        options: { show_counter: true }
      )
      expect(component.aria_describedby).to include('user_description_counter')
    end

    it 'returns nil when no describedby IDs are present' do
      component = FormFieldComponent.new(form: form_object, field: :name)
      expect(component.aria_describedby).to be_nil
    end
  end

  describe '#render_field_input' do
    it 'renders text field by default' do
      component = FormFieldComponent.new(form: form_object, field: :name)
      expect(form_object).to receive(:text_field).with(:name, anything)
      component.render_field_input
    end

    it 'renders email field for email type' do
      component = FormFieldComponent.new(form: form_object, field: :email, type: :email)
      expect(form_object).to receive(:email_field).with(:email, anything)
      component.render_field_input
    end

    it 'renders password field for password type' do
      component = FormFieldComponent.new(form: form_object, field: :password, type: :password)
      expect(form_object).to receive(:password_field).with(:password, anything)
      component.render_field_input
    end

    it 'renders textarea for textarea type' do
      component = FormFieldComponent.new(form: form_object, field: :description, type: :textarea)
      expect(form_object).to receive(:text_area).with(:description, anything)
      component.render_field_input
    end


    it 'renders phone field for phone type (normalized to tel)' do
      component = FormFieldComponent.new(form: form_object, field: :phone, type: :phone)
      expect(form_object).to receive(:telephone_field).with(:phone, anything)
      component.render_field_input
    end

    it 'renders tel field for tel type' do
      component = FormFieldComponent.new(form: form_object, field: :phone, type: :tel)
      expect(form_object).to receive(:telephone_field).with(:phone, anything)
      component.render_field_input
    end
  end

  describe 'field type normalization' do
    it 'treats :phone and :tel fields identically' do
      phone_component = FormFieldComponent.new(form: form_object, field: :phone, type: :phone)
      tel_component = FormFieldComponent.new(form: form_object, field: :phone, type: :tel)

      expect(phone_component.input_field_classes).to eq(tel_component.input_field_classes)
    end
  end

  describe 'rendering' do
    subject(:rendered_component) do
      render_inline(FormFieldComponent.new(form: form_object, field: :name, required: true))
    end

    it 'renders the form field container' do
      expect(rendered_component.css('.form-field')).to be_present
    end

    it 'renders required indicator for required fields' do
      expect(rendered_component.css('span').text).to include('*')
    end

    it 'renders error container' do
      expect(rendered_component.css('#user_name_error')).to be_present
    end

    it 'includes accessibility attributes' do
      component = FormFieldComponent.new(form: form_object, field: :name, required: true)
      attrs = component.field_attributes
      expect(attrs['aria-invalid']).to eq('false')
    end

    context 'with errors' do
      let(:field_errors) { [ 'is required' ] }
      let(:has_errors) { true }

      subject(:rendered_component) do
        render_inline(FormFieldComponent.new(form: form_object, field: :name, required: true))
      end

      it 'displays error message' do
        expect(rendered_component.css('.form-error-message').text).to include('is required')
      end

      it 'sets aria-invalid to true' do
        component = FormFieldComponent.new(form: form_object, field: :name, required: true)
        attrs = component.field_attributes
        expect(attrs['aria-invalid']).to eq('true')
      end
    end

    context 'with helper text' do
      subject(:rendered_component) do
        render_inline(FormFieldComponent.new(
          form: form_object,
          field: :name,
          options: { helper_text: 'This is help text' }
        ))
      end

      it 'displays helper text when no errors' do
        expect(rendered_component.css('.form-helper-text').text).to include('This is help text')
      end
    end
  end
end

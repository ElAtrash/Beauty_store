import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["email", "password", "passwordConfirmation"]

  connect() {
    this.hasInteracted = {};
    this.setupEventListeners();
    this.setupTranslations();
  }

  setupTranslations() {
    const locale = document.documentElement.lang || 'en';

    this.translations = {
      en: {
        email_required: 'Email is required.',
        email_invalid: 'Email is not valid.',
        password_required: 'Password is required.',
        password_too_short: 'Password must be at least 8 characters.',
        password_confirmation_required: 'Password confirmation is required.',
        passwords_dont_match: 'Passwords do not match.'
      },
      ar: {
        email_required: 'البريد الإلكتروني مطلوب.',
        email_invalid: 'البريد الإلكتروني غير صالح.',
        password_required: 'كلمة المرور مطلوبة.',
        password_too_short: 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.',
        password_confirmation_required: 'تأكيد كلمة المرور مطلوب.',
        passwords_dont_match: 'كلمات المرور غير متطابقة.'
      }
    };

    this.currentTranslations = this.translations[locale] || this.translations.en;
  }

  setupEventListeners() {
    if (this.hasEmailTarget) {
      this.emailTarget.addEventListener('blur', () => {
        this.hasInteracted.email = true;
        this.validateEmail();
      });
      this.emailTarget.addEventListener('input', () => {
        if (this.hasInteracted.email) {
          this.validateEmail();
        }
      });
    }

    if (this.hasPasswordTarget) {
      this.passwordTarget.addEventListener('blur', () => {
        this.hasInteracted.password = true;
        this.validatePassword();
        if (this.hasPasswordConfirmationTarget && this.hasInteracted.passwordConfirmation) {
          this.validatePasswordConfirmation();
        }
      });
      this.passwordTarget.addEventListener('input', () => {
        if (this.hasInteracted.password) {
          this.validatePassword();
        }
        if (this.hasPasswordConfirmationTarget && this.hasInteracted.passwordConfirmation) {
          this.validatePasswordConfirmation();
        }
      });
    }

    if (this.hasPasswordConfirmationTarget) {
      this.passwordConfirmationTarget.addEventListener('blur', () => {
        this.hasInteracted.passwordConfirmation = true;
        this.validatePasswordConfirmation();
      });
      this.passwordConfirmationTarget.addEventListener('input', () => {
        if (this.hasInteracted.passwordConfirmation) {
          this.validatePasswordConfirmation();
        }
      });
    }

    this.element.addEventListener('submit', (e) => {
      this.hasInteracted = { email: true, password: true, passwordConfirmation: true };
      const valid = this.validateAllFields();
      if (!valid) {
        e.preventDefault();
      }
    });
  }

  validateAllFields() {
    let valid = true;

    if (this.hasEmailTarget && !this.validateEmail()) valid = false;
    if (this.hasPasswordTarget && !this.validatePassword()) valid = false;
    if (this.hasPasswordConfirmationTarget && !this.validatePasswordConfirmation()) valid = false;

    return valid;
  }

  validateEmail() {
    if (!this.hasEmailTarget) return true;

    const input = this.emailTarget;
    const value = input.value.trim();
    let message = '';

    if (!this.hasInteracted.email) return !!value;

    if (!value) {
      message = this.currentTranslations.email_required;
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value)) {
      message = this.currentTranslations.email_invalid;
    }

    this.setFieldValidation(input, message);
    return !message;
  }

  validatePassword() {
    if (!this.hasPasswordTarget) return true;

    const input = this.passwordTarget;
    const value = input.value;
    let message = '';

    if (!this.hasInteracted.password) return !!value;

    if (!value) {
      message = this.currentTranslations.password_required;
    } else if (value.length < 8) {
      message = this.currentTranslations.password_too_short;
    }

    this.setFieldValidation(input, message);
    return !message;
  }

  validatePasswordConfirmation() {
    if (!this.hasPasswordConfirmationTarget || !this.hasPasswordTarget) return true;

    const input = this.passwordConfirmationTarget;
    const value = input.value;
    const passwordValue = this.passwordTarget.value;
    let message = '';

    if (!this.hasInteracted.passwordConfirmation) return !!value;

    if (!value) {
      message = this.currentTranslations.password_confirmation_required;
    } else if (value !== passwordValue) {
      message = this.currentTranslations.passwords_dont_match;
    }

    this.setFieldValidation(input, message);
    return !message;
  }

  setFieldValidation(input, message) {
    let errorDiv = null;

    let container = input.parentElement;
    errorDiv = container.querySelector('.text-red-600');

    if (!errorDiv && container.parentElement) {
      errorDiv = container.parentElement.querySelector('.text-red-600');
    }

    if (!errorDiv) {
      const form = input.closest('form');
      if (form) {
        const errorDivs = form.querySelectorAll('.text-red-600');
        for (let div of errorDivs) {
          if (div.closest('div').contains(input) || input.closest('div').contains(div)) {
            errorDiv = div;
            break;
          }
        }
      }
    }


    if (message) {
      input.classList.remove('border-gray-300', 'focus:border-cyan-500', 'focus:ring-cyan-500');
      input.classList.add('border-red-500', 'focus:border-red-500', 'focus:ring-red-500');

      if (errorDiv) {
        errorDiv.classList.remove('hidden');
        errorDiv.classList.add('flex', 'items-center', 'gap-1');
        const span = errorDiv.querySelector('span');
        if (span) span.textContent = message;
      }
    } else {
      input.classList.remove('border-red-500', 'focus:border-red-500', 'focus:ring-red-500');
      input.classList.add('border-gray-300', 'focus:border-cyan-500', 'focus:ring-cyan-500');

      if (errorDiv) {
        errorDiv.classList.add('hidden');
        errorDiv.classList.remove('flex', 'items-center', 'gap-1');
        const span = errorDiv.querySelector('span');
        if (span) span.textContent = '';
      }
    }
  }
}

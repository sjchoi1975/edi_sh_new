import '@/assets/buttons.css';
import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

import PrimeVue from 'primevue/config';
import Aura from '@primevue/themes/aura';
import 'primeicons/primeicons.css';

// PrimeVue 서비스 추가
import ConfirmationService from 'primevue/confirmationservice';
import ToastService from 'primevue/toastservice';

const app = createApp(App)

app.use(router)
app.use(PrimeVue, {
  theme: {
    preset: Aura,
    options: {
      prefix: 'p',
      darkModeSelector: '.my-dark-mode',
      cssLayer: true
    }
  }
});

// PrimeVue 서비스 등록
app.use(ConfirmationService);
app.use(ToastService);

app.mount('#app')
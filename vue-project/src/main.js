// import '@primevue/themes/aura/theme.css';
import 'primeicons/primeicons.css';

// 기타 전역 CSS
import '@/assets/buttons.css';
import './assets/main.css';

// JS/라이브러리 import
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';

import PrimeVue from 'primevue/config';
import Aura from '@primevue/themes/aura';
import ConfirmationService from 'primevue/confirmationservice';
import ToastService from 'primevue/toastservice';


// aura 테마 : 최신, 깔끔, 밝은 느낌
// import '@primevue/themes/aura/theme.css';

// lara 테마 : PrimeVue 공식 기본 테마, 다양한 색상(blue, teal, purple 등) 변형 가능
// import '@primevue/themes/lara/theme.css';

// material 테마 : 구글 머티리얼 스타일
// import '@primevue/themes/material/theme.css';

// nora 테마 : 심플하고 미니멀한 스타일
// import '@primevue/themes/nora/theme.css';

const app = createApp(App);

app.use(router);
app.use(PrimeVue, {
  theme: Aura, // 여기만 남기세요!
  ripple: true,
  inputStyle: 'filled',

// 전역 설정 안됨!!! 컴퍼넌트마다 지정해줘야 함!!!
  datatable: {
    paginator: true,
    rows: 20,
    rowsPerPageOptions: [20, 50, 100],
    scrollable: true,
    scrollHeight: '680px',
    loading: false,
    responsiveLayout: 'scroll',
    filterDisplay: 'menu'
  }
});

// PrimeVue 서비스 등록
app.use(ConfirmationService);
app.use(ToastService);

app.mount('#app');
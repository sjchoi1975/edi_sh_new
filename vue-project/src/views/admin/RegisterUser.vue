<label for="email">이메일</label>
<InputText id="email" v-model="form.id_login" type="email" required />

const form = ref({
  id_login: '',
  password: '',
  company_name: ''
});

email: form.value.id_login,

form.value.id_login = ''; 

.from('companies').select('approval_status').eq('email', id_login.value) 

alert(id_login.value); 

const { data: companyRow, error: companyError } = await supabase
  .from('companies')
  .select('approval_status')
  .eq('email', id_login.value)
  .maybeSingle();

console.log('companyRow:', companyRow);
console.log('companyError:', companyError); 
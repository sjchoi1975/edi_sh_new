<template>
  <header class="top-nav">
    <div class="top-nav-breadcrumb">
      <span class="breadcrumb-menu">{{ breadcrumbMenu }}</span>
      <span class="breadcrumb-sep">&gt;</span>
      <span class="breadcrumb-submenu">{{ breadcrumbSubMenu }}</span>
    </div>
    <div class="top-nav-actions">
      <i class="pi pi-bell top-nav-icon"></i>
      <i class="pi pi-user top-nav-icon"></i>
      <a href="#" class="top-nav-logout" @click.prevent="$emit('logout')">로그아웃</a>
    </div>
  </header>
</template>

<script setup>
const props = defineProps({
  breadcrumbMenu: { type: String, default: '' },
  breadcrumbSubMenu: { type: String, default: '' }
});
const emit = defineEmits(['logout']);
</script>

<style scoped>
.top-nav {
  width: 100%;
  height: 56px;
  background: #fff;
  color: #222;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 32px 0 0;
  box-sizing: border-box;
  position: fixed;
  top: 0;
  left: 220px;
  z-index: 1100;
  border-bottom: 1px solid #e5e7eb;
  box-shadow: 0 2px 8px rgba(0,0,0,0.03);
}
.top-nav-breadcrumb {
  display: flex;
  align-items: center;
  margin-left: 18px;
  font-size: 14px;
  gap: 6px;
}
.breadcrumb-menu {
  color: #222;
  font-weight: 500;
}
.breadcrumb-sep {
  color: #222;
  font-weight: 400;
  margin: 0 2px;
}
.breadcrumb-submenu {
  color: #222;
  font-weight: 700;
}
.top-nav-actions {
  display: flex;
  align-items: center;
  gap: 18px;
}
.top-nav-icon {
  font-size: 1.25rem;
  color: #5fa56b;
  cursor: pointer;
  transition: color 0.15s;
}
.top-nav-icon:hover {
  color: #388e3c;
}
.top-nav-logout {
  color: #5fa56b;
  font-size: 14px;
  text-decoration: underline;
  cursor: pointer;
  margin-left: 8px;
}
.top-nav-logout:hover {
  color: #388e3c;
}
</style> 
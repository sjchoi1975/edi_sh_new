<template>
  <header class="top-nav">
    <div class="top-nav-breadcrumb">
      <span class="breadcrumb-menu">{{ breadcrumbMenu }}</span>
      <span class="breadcrumb-sep">&gt;</span>
      <span class="breadcrumb-submenu">{{ breadcrumbSubMenu }}</span>
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

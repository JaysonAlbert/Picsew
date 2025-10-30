/** @type {import('tailwindcss').Config} */
import scrollbar from 'tailwind-scrollbar';

const config = {
  content: [
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [
    scrollbar,
  ],
};

export default config;
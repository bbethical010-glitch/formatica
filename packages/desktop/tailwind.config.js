/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        bg: '#0b1326',
        surface: '#171f33',
        'surface-low': '#131b2e',
        'surface-high': '#222a3d',
        'surface-highest': '#2d3449',
        primary: '#c4c0ff',
        'primary-container': '#5b4fe8',
        secondary: '#d0bcff',
        tertiary: '#4cd7f6',
        'on-surface': '#dae2fd',
        'on-surface-var': '#c8c4d8',
        outline: '#918fa1',
        'outline-var': '#464555',
        'audio-rose': '#E8507C',
        'video-purple': '#8b5cf6',
        'compress-orange': '#F97316',
        'merge-teal': '#10b981',
        'split-amber': '#F59E0B',
        'doc-indigo': '#6366f1',
        'grey-slate': '#64748b',
        error: '#ffb4ab',
      },
      fontFamily: {
        sans: ['Manrope', 'sans-serif'],
      },
      borderRadius: {
        DEFAULT: '1rem',
        lg: '2rem',
        xl: '3rem',
        full: '9999px',
      },
    },
  },
  plugins: [],
}

window.themeInterop = {
    initialize: function () {
        const savedTheme = localStorage.getItem("mini-social-theme") || "light";
        const savedLanguage = localStorage.getItem("mini-social-language");
        document.body.dataset.theme = savedTheme;
        if (savedLanguage) {
            document.documentElement.lang = savedLanguage;
        }
    },
    getPreferences: function () {
        return {
            theme: localStorage.getItem("mini-social-theme") || "light",
            language: localStorage.getItem("mini-social-language") || document.documentElement.lang || "vi"
        };
    },
    setTheme: function (theme) {
        const next = theme === "dark" ? "dark" : "light";
        document.body.dataset.theme = next;
        localStorage.setItem("mini-social-theme", next);
    },
    toggle: function () {
        const current = document.body.dataset.theme || "light";
        this.setTheme(current === "light" ? "dark" : "light");
    },
    setLanguage: function (language) {
        const next = language === "en" ? "en" : "vi";
        localStorage.setItem("mini-social-language", next);
        document.documentElement.lang = next;
        document.cookie = `.AspNetCore.Culture=c=${next}|uic=${next}; path=/; max-age=31536000; SameSite=Lax`;
        window.location.reload();
    }
};

window.themeInterop.initialize();

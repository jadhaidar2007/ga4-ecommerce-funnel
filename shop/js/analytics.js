(function () {
  const cfg = window.SHOP_CONFIG;
  const live = cfg.measurementId && !cfg.measurementId.includes("XXXX");

  window.dataLayer = window.dataLayer || [];
  window.gtag = function () { dataLayer.push(arguments); };

  if (live) {
    const s = document.createElement("script");
    s.async = true;
    s.src = "https://www.googletagmanager.com/gtag/js?id=" + cfg.measurementId;
    document.head.appendChild(s);
    gtag("js", new Date());
    gtag("config", cfg.measurementId, { debug_mode: cfg.debug });
  }

  // small wrapper so every event goes through one place
  window.track = function (name, params = {}) {
    if (params.items && params.value === undefined) {
      params.value = +params.items
        .reduce((sum, i) => sum + i.price * (i.quantity || 1), 0)
        .toFixed(2);
    }
    if (params.items) params.currency = cfg.currency;

    if (live) gtag("event", name, params);
    if (cfg.debug || !live) console.log("[ga4]", name, params);
  };
})();

'use strict';

const CURRENT_CONTINUATION = (new URL(document.location)).searchParams.get("continuation");
const CONT_CACHE_KEY = `continuation_cache_${encodeURIComponent(window.location.pathname)}`;

function get_continuation_cache() {
    return JSON.parse(sessionStorage.getItem(CONT_CACHE_KEY)) || [];
}

function save_current_continuation() {
    const continuation_cache = get_continuation_cache();
    continuation_cache.push(CURRENT_CONTINUATION);

    sessionStorage.setItem(CONT_CACHE_KEY, JSON.stringify(continuation_cache));
}

function handle_previous_page_button() {
    let continuation_cache = get_continuation_cache();
    if (!continuation_cache.length) return null;

    // Sanity check. Nowhere should the current continuation token exist in the cache 
    // but it can happen when using the browser's back feature. As such we'd need to travel
    // back to the point where the current continuation token first appears in order to 
    // account for the rewind.
    const conflict_at = continuation_cache.indexOf(CURRENT_CONTINUATION);
    if (conflict_at != -1) {
        continuation_cache.length = conflict_at;
    };

    const previous_continuation_token = continuation_cache.pop();

    // On the first page, the stored continuation token is null.
    if (previous_continuation_token === null) {
        sessionStorage.removeItem(CONT_CACHE_KEY);
        window.location.href = window.location.href.split('?')[0];

        return;
    };

    sessionStorage.setItem(CONT_CACHE_KEY, JSON.stringify(continuation_cache));

    window.location.href = `${window.location.pathname}?continuation=${previous_continuation_token}`;
};

addEventListener('DOMContentLoaded', function() {
    const pagination_locale_strings = JSON.parse(document.getElementById('pagination_locale_strings').textContent);

    const next_page_containers = document.getElementsByClassName("page-next-container");

    for (let container of next_page_containers) {
        container.getElementsByClassName("pure-button")[0].addEventListener("click", save_current_continuation);
    };

    // Only add previous page buttons when not on the first page
    if (CURRENT_CONTINUATION) {
        const prev_page_containers = document.getElementsByClassName("page-prev-container")

        for (let container of prev_page_containers) {
            if (pagination_locale_strings.is_locale_rtl) {
                container.innerHTML = `<a href="#" class="pure-button pure-button-secondary">${pagination_locale_strings.prev_page_locale_string}</a>&nbsp;&nbsp;<i class="icon ion-ios-arrow-forward"></i>`
            } else {
                container.innerHTML = `<a href="#" class="pure-button pure-button-secondary"><i class="icon ion-ios-arrow-back"></i>&nbsp;&nbsp;${pagination_locale_strings.prev_page_locale_string}</a>`
            };
            container.getElementsByClassName("pure-button")[0].addEventListener("click", handle_previous_page_button);
        };
    }
});
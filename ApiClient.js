// ApiClient.js
.pragma library
.import "Config.js" as Config

var _baseUrl = String(Config.apiBase || "http://localhost:5032").replace(/\/+$/, "");
var _timeoutMs = 15000;

function setBaseUrl(url) {
    if (!url) throw new Error("BaseUrl is required");
    _baseUrl = String(url).replace(/\/+$/, "");
    Config.apiBase = _baseUrl;
}

function getBaseUrl() { return _baseUrl; }

function _qs(params) {
    if (!params) return "";
    var parts = [];
    Object.keys(params).forEach(function (k) {
        var v = params[k];
        if (v === undefined || v === null || v === "") return;
        parts.push(encodeURIComponent(k) + "=" + encodeURIComponent(String(v)));
    });
    return parts.length ? ("?" + parts.join("&")) : "";
}

function _parseJsonSafe(text) {
    if (!text) return null;
    try { return JSON.parse(text); } catch (e) { return null; }
}

function _request(method, path, options) {
    options = options || {};
    var query = options.query || null;
    var body = (options.hasOwnProperty("body") ? options.body : undefined);

    var url = _baseUrl + path + _qs(query);

    return new Promise(function (resolve, reject) {
        var xhr = new XMLHttpRequest();
        xhr.open(method, url);

        xhr.timeout = _timeoutMs;
        xhr.setRequestHeader("Accept", "application/json");

        if (body !== undefined) {
            xhr.setRequestHeader("Content-Type", "application/json");
        }

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;

            var status = xhr.status;
            var json = _parseJsonSafe(xhr.responseText);

            if (status >= 200 && status < 300) {
                resolve(json);
                return;
            }

            var msg = (json && (json.message || json.error))
                ? (json.message || json.error)
                : (xhr.responseText ? xhr.responseText : ("HTTP " + status));

            reject(new Error(msg));
        };

        xhr.ontimeout = function () {
            reject(new Error("Request timed out: " + method + " " + path));
        };

        xhr.onerror = function () {
            reject(new Error("Network error: " + method + " " + path));
        };

        if (body === undefined) xhr.send();
        else xhr.send(JSON.stringify(body));
    });
}

function _requireField(obj, field) {
    if (!obj || obj[field] === undefined || obj[field] === null || obj[field] === "")
        throw new Error("Missing required field: " + field);
}

function _normalizeItemPayload(item) {
    _requireField(item, "householdId");
    _requireField(item, "name");
    _requireField(item, "count");

    return {
        householdId: String(item.householdId),
        categoryId: (item.categoryId === undefined || item.categoryId === "" ? null : item.categoryId),
        name: String(item.name),
        count: Number(item.count),

        description: (item.description === undefined ? null : item.description),

        unit: (item.unit === undefined || item.unit === null || item.unit === "" ? "pcs" : String(item.unit)),

        minCount: (item.minCount === undefined ? null : item.minCount),
        saleCount: (item.saleCount === undefined ? null : item.saleCount),
        incrementStep: (item.incrementStep === undefined || item.incrementStep === null ? 1 : Number(item.incrementStep))
    };
}


// ---------------- Households ----------------

function listHouseholds() {
    return _request("GET", "/api/households");
}

function getHousehold(id) {
    _requireField({ id: id }, "id");
    return _request("GET", "/api/households/" + encodeURIComponent(id));
}

function createHousehold(household) {
    _requireField(household, "name");
    return _request("POST", "/api/households", { body: { name: String(household.name) } });
}

function updateHousehold(id, household) {
    _requireField({ id: id }, "id");
    _requireField(household, "name");
    return _request("PUT", "/api/households/" + encodeURIComponent(id), { body: { name: String(household.name) } });
}

function deleteHousehold(id) {
    _requireField({ id: id }, "id");
    return _request("DELETE", "/api/households/" + encodeURIComponent(id));
}


// ---------------- Categories ----------------

function listCategories(householdId) {
    _requireField({ householdId: householdId }, "householdId");
    return _request("GET", "/api/categories", { query: { householdId: householdId } });
}

function getCategory(id) {
    _requireField({ id: id }, "id");
    return _request("GET", "/api/categories/" + encodeURIComponent(id));
}

var _categoryNameCache = {};
function getCategoryName(categoryId) {
    if (!categoryId) return Promise.resolve("Uncategorized");
    if (_categoryNameCache[categoryId])
        return Promise.resolve(_categoryNameCache[categoryId]);

    return getCategory(categoryId)
        .then(cat => {
            _categoryNameCache[categoryId] = cat.name || "Uncategorized";
            return _categoryNameCache[categoryId];
        })
        .catch(() => "Uncategorized");
}

function createCategory(category) {
    _requireField(category, "householdId");
    _requireField(category, "name");
    return _request("POST", "/api/categories", {
        body: {
            householdId: String(category.householdId),
            name: String(category.name)
        }
    });
}

function updateCategory(id, category) {
    _requireField({ id: id }, "id");
    _requireField(category, "name");
    return _request("PUT", "/api/categories/" + encodeURIComponent(id), {
        body: { name: String(category.name) }
    });
}

function deleteCategory(id) {
    _requireField({ id: id }, "id");
    return _request("DELETE", "/api/categories/" + encodeURIComponent(id));
}


// ---------------- Items ----------------

function listItems(householdId, categoryId /* optional */) {
    _requireField({ householdId: householdId }, "householdId");
    return _request("GET", "/api/items", {
        query: {
            householdId: householdId,
            categoryId: (categoryId ? categoryId : null)
        }
    });
}

function getItem(id) {
    _requireField({ id: id }, "id");
    return _request("GET", "/api/items/" + encodeURIComponent(id));
}

function searchItems(q, householdId, categoryId /* optional */) {
    _requireField({ q: q }, "q");
    _requireField({ householdId: householdId }, "householdId");
    return _request("GET", "/api/items/search", {
        query: {
            q: q,
            householdId: householdId,
            categoryId: (categoryId ? categoryId : null)
        }
    });
}

function createItem(item) {
    var payload = _normalizeItemPayload(item);
    return _request("POST", "/api/items", { body: payload });
}

function updateItem(id, item) {
    _requireField({ id: id }, "id");
    var payload = _normalizeItemPayload(item);

    var updatePayload = {
        categoryId: payload.categoryId,
        name: payload.name,
        count: payload.count,
        description: payload.description,
        unit: payload.unit,
        minCount: payload.minCount,
        saleCount: payload.saleCount,
        incrementStep: payload.incrementStep
    };

    return _request("PUT", "/api/items/" + encodeURIComponent(id), { body: updatePayload });
}

function deleteItem(id) {
    _requireField({ id: id }, "id");
    return _request("DELETE", "/api/items/" + encodeURIComponent(id));
}

function patchItemCount(id, stepIncrement) {
    _requireField({ id: id }, "id");
    if (stepIncrement === undefined || stepIncrement === null || Number(stepIncrement) === 0)
        throw new Error("stepIncrement (delta) must be non-zero");

    return _request("PATCH", "/api/items/" + encodeURIComponent(id) + "/count", {
        body: { delta: Number(stepIncrement) }
    });
}

function incrementItemCount(item) {
    _requireField(item, "id");
    var step = (item.incrementStep === undefined || item.incrementStep === null) ? 1 : Number(item.incrementStep);
    return patchItemCount(item.id, +step);
}

function decrementItemCount(item) {
    _requireField(item, "id");
    var step = (item.incrementStep === undefined || item.incrementStep === null) ? 1 : Number(item.incrementStep);
    return patchItemCount(item.id, -step);
}


var ApiClient = {
    setBaseUrl: setBaseUrl,
    getBaseUrl: getBaseUrl,

    listHouseholds: listHouseholds,
    getHousehold: getHousehold,
    createHousehold: createHousehold,
    updateHousehold: updateHousehold,
    deleteHousehold: deleteHousehold,

    listCategories: listCategories,
    getCategory: getCategory,
    createCategory: createCategory,
    updateCategory: updateCategory,
    deleteCategory: deleteCategory,
    getCategoryName: getCategoryName,

    listItems: listItems,
    getItem: getItem,
    searchItems: searchItems,
    createItem: createItem,
    updateItem: updateItem,
    deleteItem: deleteItem,
    patchItemCount: patchItemCount,
    incrementItemCount: incrementItemCount,
    decrementItemCount: decrementItemCount
};

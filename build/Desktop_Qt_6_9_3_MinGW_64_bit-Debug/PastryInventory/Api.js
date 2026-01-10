// api.js
.pragma library

var BASE_URL = "http://localhost:5032";

function qs(params) {
    var parts = [];
    for (var k in params) {
        if (params[k] === undefined || params[k] === null || params[k] === "") continue;
        parts.push(encodeURIComponent(k) + "=" + encodeURIComponent(params[k]));
    }
    return parts.length ? ("?" + parts.join("&")) : "";
}

function request(method, path, body, cb) {
    var xhr = new XMLHttpRequest();
    xhr.open(method, BASE_URL + path);
    xhr.setRequestHeader("Content-Type", "application/json");

    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;

        var ok = xhr.status >= 200 && xhr.status < 300;
        var data = null;

        try {
            data = xhr.responseText ? JSON.parse(xhr.responseText) : null;
        } catch (e) {
            data = null;
        }

        cb(ok, xhr.status, data, xhr.responseText);
    };

    xhr.send(body ? JSON.stringify(body) : null);
}

// -------- Households --------

function getHouseholds(cb) {
    request("GET", "/api/households", null, cb);
}

// (only if you implemented these endpoints)
function createHousehold(name, note, cb) {
    request("POST", "/api/households", { name: name, note: note }, cb);
}
function updateHousehold(id, name, note, cb) {
    request("PUT", "/api/households/" + id, { name: name, note: note }, cb);
}
function deleteHousehold(id, cb) {
    request("DELETE", "/api/households/" + id, null, cb);
}

// -------- Items --------

function getItems(opts, cb) {
    // opts: { householdId, maxCount, category }
    request("GET", "/api/items" + qs(opts || {}), null, cb);
}

function searchItems(q, householdId, cb) {
    request("GET", "/api/items/search" + qs({ q: q, householdId: householdId }), null, cb);
}

function getItemById(id, cb) {
    request("GET", "/api/items/" + id, null, cb);
}

function createItem(dto, cb) {
    // dto: { householdId, name, count, detail, category }
    request("POST", "/api/items", dto, cb);
}

function updateItem(id, dto, cb) {
    // dto: { name, count, detail, category }
    request("PUT", "/api/items/" + id, dto, cb);
}

function deleteItem(id, cb) {
    request("DELETE", "/api/items/" + id, null, cb);
}

function changeItemCount(id, delta, cb) {
    // requires PATCH /api/items/{id}/count endpoint
    request("PATCH", "/api/items/" + id + "/count", { delta: delta }, cb);
}

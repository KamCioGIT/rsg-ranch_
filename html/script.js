const buyMenu = document.getElementById('buy-menu');
const sellMenu = document.getElementById('sell-menu');
const bossMenu = document.getElementById('boss-menu');
const livestockMenu = document.getElementById('livestock-menu');
const statusMenu = document.getElementById('status-menu');

const buyContent = document.getElementById('buy-content');
const sellContent = document.getElementById('sell-content');
const livestockContent = document.getElementById('livestock-content');
const statusContent = document.getElementById('status-content');

// Listen for messages from Lua
window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === "openBuyMenu") {
        openBuyMenu(data.items);
    } else if (data.action === "openSellMenu") {
        openSellMenu(data.items);
    } else if (data.action === "openBossMenu") {
        openBossMenu(data.ranchData);
    } else if (data.action === "openLivestockMenu") {
        openLivestockMenu(data.items);
    } else if (data.action === "openAnimalStatus") {
        openAnimalStatus(data.status);
    } else if (data.action === "openProgressBar") {
        startProgressBar(data.duration, data.label);
    } else if (data.action === "close") {
        closeMenu();
    }
});

function hideAll() {
    buyMenu.classList.add('hidden');
    sellMenu.classList.add('hidden');
    bossMenu.classList.add('hidden');
    if (livestockMenu) livestockMenu.classList.add('hidden');
    if (statusMenu) statusMenu.classList.add('hidden');
    document.getElementById('custom-progress-container').classList.add('hidden');
}

function openBuyMenu(items) {
    hideAll();
    buyContent.innerHTML = "";

    items.forEach(item => {
        const div = document.createElement('div');
        div.className = "item-card";
        div.innerHTML = `
            <div class="img-container" style="width:64px;height:64px;margin:0 auto;display:flex;align-items:center;justify-content:center;">
                <img src="./assets/${item.model}.png" alt="${item.label}" style="max-width:100%;max-height:100%;" onerror="handleImageError(this)">
            </div>
            <div class="item-title">${item.label}</div>
            <div class="item-price">$${item.price} each</div>
            <div style="margin: 5px 0;">
                <input type="number" id="qty-${item.model}" value="1" min="1" max="10" style="width: 50px; text-align: center; background: rgba(0,0,0,0.1); border: 1px solid #5c4033; color: inherit; font-family: inherit;">
            </div>
            <button class="item-btn" onclick="buyItem('${item.model}', ${item.price}, document.getElementById('qty-${item.model}').value)">Purchase</button>
        `;
        buyContent.appendChild(div);
    });

    buyMenu.classList.remove('hidden');
}

function handleImageError(img) {
    img.style.display = 'none';
    img.parentElement.innerHTML = '<i class="fa-solid fa-paw" style="font-size:32px;opacity:0.5;"></i>';
}

function openSellMenu(items) {
    hideAll();
    sellContent.innerHTML = "";

    if (items.length === 0) {
        sellContent.innerHTML = "<div style='width:100%;text-align:center;'>No animals to sell nearby.</div>";
    }

    items.forEach(item => {
        const div = document.createElement('div');
        div.className = "item-card";
        div.innerHTML = `
             <div class="img-container" style="width:64px;height:64px;margin:0 auto;display:flex;align-items:center;justify-content:center;">
                <img src="./assets/${item.model}.png" alt="${item.model}" style="max-width:100%;max-height:100%;" onerror="handleImageError(this)">
             </div>
            <div class="item-title">${item.label || item.model}</div>
            <div class="item-price">Offer: $${item.price}</div>
            <div style="font-size:0.8rem; margin-bottom:5px;">Age: ${item.age} days</div>
            <button class="item-btn" onclick="sellItem('${item.id}')">Accept Offer</button>
        `;
        sellContent.appendChild(div);
    });

    sellMenu.classList.remove('hidden');
}

// Global function for inline onclick to ensure it always works
window.spawnSpecificAnimal = function (id) {
    console.log("Spawn button clicked (Global) for ID:", id);
    // Force string conversion just in case
    postAction('spawnSpecific', { id: String(id) });
    setTimeout(() => closeMenu(), 100);
};

function openLivestockMenu(items) {
    hideAll();
    livestockContent.innerHTML = "";

    if (!items || items.length === 0) {
        livestockContent.innerHTML = "<div style='width:100%;text-align:center;'>You have no animals.</div>";
    } else {
        items.forEach(item => {
            // Ensure we have a valid ID to send
            let actualId = item.animalid || item.id;

            const div = document.createElement('div');
            div.className = "item-card";

            // Fallback if both are missing (should not happen if DB returns correct data)
            if (!actualId) {
                console.error("Missing ID for item:", item);
                actualId = "INVALID_ID";
            }

            // Using inline onclick with the global function is often more robust in these simplified NUI browsers
            div.innerHTML = `
                 <div class="img-container" style="width:64px;height:64px;margin:0 auto;display:flex;align-items:center;justify-content:center;">
                    <img src="./assets/${item.model}.png" alt="${item.model}" style="max-width:100%;max-height:100%;" onerror="handleImageError(this)">
                 </div>
                <div class="item-title">${item.model}</div>
                <div class="item-price">ID: ${actualId}</div>
                <button class="item-btn" type="button" onclick="window.spawnSpecificAnimal('${actualId}')">Spawn</button>
            `;

            livestockContent.appendChild(div);
        });
    }
    livestockMenu.classList.remove('hidden');
}

function openBossMenu(data) {
    hideAll();

    document.getElementById('ranch-name').innerText = data.name;
    document.getElementById('ranch-funds').innerText = "$" + data.funds;
    document.getElementById('ranch-employees').innerText = data.employees;
    document.getElementById('ranch-animals').innerText = data.animals;

    // Add Manage/Spawn Animals Button
    let spawnBtn = document.getElementById('manage-herd-btn');
    if (!spawnBtn) {
        spawnBtn = document.createElement('button');
        spawnBtn.id = 'manage-herd-btn';
        spawnBtn.className = 'menu-btn';
        spawnBtn.style.marginTop = '20px';
        spawnBtn.style.width = '100%';
        spawnBtn.style.fontWeight = 'bold';
        spawnBtn.innerHTML = 'MANAGE / SPAWN HERD';
        spawnBtn.onclick = function () {
            postAction('getLivestock', {});
        };
        bossMenu.querySelector('.ui-content').appendChild(spawnBtn);
    }

    bossMenu.classList.remove('hidden');
}

function postAction(action, data) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    });
}

function closeMenu() {
    hideAll();
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

function buyItem(model, price, amount) {
    amount = parseInt(amount) || 1;
    if (amount < 1) amount = 1;

    fetch(`https://${GetParentResourceName()}/buyItem`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            model: model,
            price: price,
            amount: amount
        })
    });
}

function sellItem(id) {
    fetch(`https://${GetParentResourceName()}/sellItem`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            id: id
        })
    });
    closeMenu();
}

// Close on Escape key
document.onkeyup = function (data) {
    if (data.which == 27) {
        closeMenu();
    }
};

function openAnimalStatus(data) {
    hideAll();
    statusContent.innerHTML = `
        <div class="status-row">
            <div class="stat-box" style="flex: 1;">
                <h3>Health</h3>
                <div style="background:#5d403755; width:100%; height:20px; border:1px solid var(--border-color); position: relative;">
                    <div style="background:linear-gradient(90deg, #8b0000, #ff4444); width:${data.health}%; height:100%;"></div>
                </div>
                <span>${data.health}%</span>
            </div>
            <div class="stat-box" style="flex: 1;">
                <h3>Hunger</h3>
                <div style="background:#5d403755; width:100%; height:20px; border:1px solid var(--border-color); position: relative;">
                    <div style="background:linear-gradient(90deg, #d35400, #e67e22); width:${data.hunger}%; height:100%;"></div>
                </div>
                <span>${data.hunger}%</span>
            </div>
        </div>

        <div class="status-info">
            <span><strong>Age:</strong> ${data.age} days</span>
            <span><strong>Gender:</strong> ${data.gender}</span>
        </div>
        
        <div style="margin-top:10px; text-align:center; font-family:var(--body-font); font-weight:bold; color: var(--gold); border-top: 1px solid var(--gold-dim); padding-top: 10px; font-size: 1.1rem; text-shadow: 1px 1px 2px black;">
            ${(function () {
            if (data.nextGrowth === "Fully Grown") return "Status: Fully Grown";
            if (data.hunger < 30) return "Growth Paused (Needs Food)";
            let now = Math.floor(Date.now() / 1000);
            let diff = data.nextGrowth - now;
            if (diff <= 0) return "Growth Pending...";
            let mins = Math.floor(diff / 60);
            let secs = diff % 60;
            return `Next Stage Breakdown: ${mins}m ${secs}s`;
        })()}
        </div>
    `;
    statusMenu.classList.remove('hidden');
}

function startProgressBar(duration, label) {
    const container = document.getElementById('custom-progress-container');
    const labelEl = document.getElementById('progress-label');
    const fillEl = document.getElementById('progress-fill');

    labelEl.innerText = label || "Processing...";
    fillEl.style.width = '0%';
    container.classList.remove('hidden');

    let startTime = null;

    function step(timestamp) {
        if (!startTime) startTime = timestamp;
        const progress = timestamp - startTime;
        const percent = Math.min((progress / duration) * 100, 100);

        fillEl.style.width = percent + '%';

        if (progress < duration) {
            window.requestAnimationFrame(step);
        } else {
            setTimeout(() => {
                container.classList.add('hidden');
                // Notify Lua finished? Lua waits on its own timer, UI is just visual here.
            }, 200);
        }
    }

    window.requestAnimationFrame(step);
}

const buyMenu = document.getElementById('buy-menu');
const sellMenu = document.getElementById('sell-menu');
const bossMenu = document.getElementById('boss-menu');
const livestockMenu = document.getElementById('livestock-menu');
const statusMenu = document.getElementById('status-menu');

const buyContent = document.getElementById('buy-content');
const sellContent = document.getElementById('sell-content');
const livestockContent = document.getElementById('livestock-content');
const statusContent = document.getElementById('status-content');
const craftingContent = document.getElementById('crafting-content');
const craftingMenu = document.getElementById('crafting-menu');

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
    } else if (data.action === "openCrafting") {
        openCraftingMenu(data.recipes);
    } else if (data.action === "close") {
        closeMenu();
    } else if (data.action === "openHireMenu") {
        openHireMenu(data.players);
    } else if (data.action === "openEmployeeList") {
        openEmployeeList(data.employees);
    }
});

function openHireMenu(players) {
    const listMenu = document.getElementById('employee-list-menu'); // Reuse same container structure if possible or create new? 
    // Let's create a dedicated one or repurpose. Reusing is easier, just changing title.

    // Check if we have a dedicated hire menu container, if not let's dynamically change the existing list menu
    // Actually better to have separate ID to avoid confusion
    let hireMenu = document.getElementById('hire-player-menu');
    let container = document.getElementById('hire-player-content');

    // Hide all
    document.querySelectorAll('.ranch-ui-container, .crafting-ui-container, .hidden').forEach(el => {
        if (!el.classList.contains('hidden')) el.classList.add('hidden');
    });

    hireMenu.classList.remove('hidden');
    hireMenu.classList.add('ranch-ui-container');

    container.innerHTML = '';

    if (!players || players.length === 0) {
        container.innerHTML = '<div style="text-align:center; color:#aaa; padding:20px;">No nearby players found.</div>';
        return;
    }

    players.forEach(p => {
        const row = document.createElement('div');
        row.className = 'employee-row';
        row.style.cssText = 'display:flex; justify-content:space-between; align-items:center; padding:15px; background:rgba(0,0,0,0.3); border:1px solid var(--gold-dim); border-radius:4px; margin-bottom:10px;';

        row.innerHTML = `
            <div style="display:flex; flex-direction:column;">
                <span class="item-title" style="font-size:1.2rem;">${p.name}</span>
                <span style="font-size:0.9rem; color:#aaa;">ID: ${p.id}</span>
            </div>
            <button class="item-btn" style="min-width:80px;" onclick="hirePlayer(${p.id})">HIRE</button>
        `;
        container.appendChild(row);
    });
}

function hirePlayer(id) {
    postAction('confirmHire', { id: id });
    closeMenu(); // Close after hiring
}

function hideAll() {
    const ids = [
        'buy-menu', 'sell-menu', 'boss-menu', 'livestock-menu',
        'status-menu', 'crafting-menu', 'employee-list-menu',
        'hire-player-menu', 'custom-progress-container'
    ];

    ids.forEach(id => {
        const el = document.getElementById(id);
        if (el) el.classList.add('hidden');
    });
}

function openEmployeeList(employees) {
    try {
        console.log("JS: Rendering employee list...", employees);
        hideAll();

        const listMenu = document.getElementById('employee-list-menu');
        const container = document.getElementById('employee-list-content');

        if (!listMenu) {
            console.error("JS: employee-list-menu element not found!");
            return;
        }
        if (!container) {
            console.error("JS: employee-list-content element not found!");
            return;
        }

        // Show this menu
        listMenu.classList.remove('hidden');

        container.innerHTML = '';

        // Add HIRE Button
        const hireBtnContainer = document.createElement('div');
        hireBtnContainer.style.textAlign = 'right';
        hireBtnContainer.style.marginBottom = '10px';
        hireBtnContainer.innerHTML = `<button class="item-btn" style="width:auto; padding:5px 15px;" onclick="postAction('manageStaff', {})">+ HIRE NEW EMPLOYEE</button>`;
        container.appendChild(hireBtnContainer);

        if (!employees || employees.length === 0) {
            container.innerHTML += '<div style="text-align:center; color:#aaa; padding:20px;">No employees found.</div>';
            return;
        }

        employees.forEach(emp => {
            const row = document.createElement('div');
            row.className = 'employee-row';
            row.style.display = 'flex';
            row.style.justifyContent = 'space-between';
            row.style.alignItems = 'center';
            row.style.padding = '15px';
            row.style.background = 'rgba(0,0,0,0.3)';
            row.style.border = '1px solid var(--gold-dim)';
            row.style.borderRadius = '4px';
            row.style.marginBottom = '10px';

            const statusColor = emp.online ? '#4caf50' : '#f44336';

            row.innerHTML = `
                <div style="display:flex; flex-direction:column;">
                    <span class="item-title" style="font-size:1.2rem;">${emp.name}</span>
                    <span style="font-size:0.9rem; color:#aaa;">Grade: ${emp.grade} (${emp.gradeLevel})</span>
                </div>
                <div style="display:flex; align-items:center; gap:10px;">
                     <span style="color:${statusColor}; font-size:0.9rem; margin-right:10px;"><i class="fa-solid fa-circle" style="font-size:0.6rem;"></i> ${emp.online ? 'Online' : 'Offline'}</span>
                     
                     <button class="item-btn" style="background:none; border:1px solid var(--gold); color:var(--gold); min-width:80px;" 
                     onclick="promoteEmployee('${emp.citizenid}', ${emp.gradeLevel})">PROMOTE</button>

                     <button class="item-btn" style="background:none; border:1px solid #d32f2f; color:#d32f2f; min-width:80px;" 
                     onclick="fireEmployee('${emp.citizenid}', '${emp.name}')">FIRE</button>
                </div>
            `;
            container.appendChild(row);
        });
    } catch (err) {
        console.error("JS Error inside openEmployeeList:", err);
    }
}

function promoteEmployee(citizenid, currentGrade) {
    // Current grades: 0, 1, 2, 3, 4
    if (currentGrade >= 4) {
        // Can't promote Boss further
        return;
    }
    let newGrade = currentGrade + 1;
    postAction('confirmPromote', { player: true, id: citizenid, grade: newGrade });
}


function fireEmployee(citizenid, name) {
    // We can add a simple confirmation if needed, but for now direct fire
    postAction('confirmFire', { citizenid: citizenid });
}

function hideAll() {
    buyMenu.classList.add('hidden');
    sellMenu.classList.add('hidden');
    bossMenu.classList.add('hidden');
    if (livestockMenu) livestockMenu.classList.add('hidden');
    if (statusMenu) statusMenu.classList.add('hidden');
    if (craftingMenu) craftingMenu.classList.add('hidden');

    // Employee Menus
    const empMenu = document.getElementById('employee-list-menu');
    if (empMenu) empMenu.classList.add('hidden');

    const hireMenu = document.getElementById('hire-player-menu');
    if (hireMenu) hireMenu.classList.add('hidden');

    document.getElementById('custom-progress-container').classList.add('hidden');
}

function openBuyMenu(items) {
    hideAll();
    buyContent.innerHTML = "";

    items.forEach(item => {
        const div = document.createElement('div');
        div.className = "item-card";
        // Increased image size from 64px to 120px
        div.innerHTML = `
            <div class="img-container" style="width:120px;height:120px;margin:0 auto;display:flex;align-items:center;justify-content:center;">
                <img src="./assets/${item.model}.png" alt="${item.label}" style="max-width:100%;max-height:100%;" onerror="handleImageError(this)">
            </div>
            <div class="item-title" style="margin-top:10px;">${item.label}</div>
            <div class="item-price">$${item.price} each</div>
            <div style="margin: 10px 0; display:flex; align-items:center; justify-content:center; gap:5px;">
                <button class="qty-btn" onclick="adjustBuyQuantity('${item.model}', -1)">-</button>
                <input type="number" id="qty-${item.model}" class="qty-input-field" value="1" min="1" max="10" style="width:50px; text-align:center;">
                <button class="qty-btn" onclick="adjustBuyQuantity('${item.model}', 1)">+</button>
            </div>
            <button class="item-btn" onclick="buyItem('${item.model}', ${item.price}, document.getElementById('qty-${item.model}').value)">Purchase</button>
        `;
        buyContent.appendChild(div);
    });

    buyMenu.classList.remove('hidden');
}

function adjustBuyQuantity(model, delta) {
    const input = document.getElementById(`qty-${model}`);
    if (!input) return;

    let val = parseInt(input.value) || 1;
    val += delta;

    if (val < 1) val = 1;
    if (val > 10) val = 10; // Hard cap from server logic

    input.value = val;
}

function handleImageError(img) {
    // Hide the broken image entirely to keep UI clean, 
    // or replace with a generic subtle texture if desired. 
    // Do NOT replace with a paw icon.
    img.style.display = 'none';

    // Check if parent is a crafting icon container and hide it too if empty
    if (img.parentElement.classList.contains('crafting-icon-elegant') ||
        img.parentElement.classList.contains('img-container')) {
        // Create a transparent placeholder or just leave empty
        // Adding a sophisticated border or text could work, but empty is cleanest for now
        let placeholder = document.createElement('i');
        placeholder.className = "fa-solid fa-box"; // Use a generic box instead of paw
        placeholder.style.fontSize = "2rem";
        placeholder.style.color = "#444";
        img.parentElement.appendChild(placeholder);
    }
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
             <div class="img-container" style="width:120px;height:120px;margin:0 auto;display:flex;align-items:center;justify-content:center;">
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

// Helper for Age
function calculateAge(bornTime) {
    if (!bornTime) return "Unknown";
    const now = Math.floor(Date.now() / 1000); // Current unix timestamp
    const diff = now - bornTime;
    const days = Math.floor(diff / 86400); // 86400 seconds in a day

    if (days < 0) return "0 Days"; // Clock drift protection
    if (days === 0) return "0 Days";
    if (days === 1) return "1 Day";
    return days + " Days";
}

function formatModelName(model) {
    if (!model) return "Unknown";
    // Remove a_c_ prefix and underscores, then Title Case
    return model.replace(/^a_c_/i, '').replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

function openLivestockMenu(items) {
    hideAll();
    livestockContent.innerHTML = "";

    if (!items || items.length === 0) {
        livestockContent.innerHTML = "<div style='width:100%;text-align:center;'>You have no animals.</div>";
    } else {
        items.forEach(item => {
            let actualId = item.animalid || item.id;
            let displayName = item.name || formatModelName(item.model);
            let displayAge = calculateAge(item.born);

            const div = document.createElement('div');
            div.className = "item-card";

            if (!actualId) {
                console.error("Missing ID for item:", item);
                actualId = "INVALID_ID";
            }

            // Updated Layout: Clean Name, Age, Spawn Button (No ID, No Type line)
            div.innerHTML = `
                 <div class="img-container" style="width:120px;height:120px;margin:0 auto;display:flex;align-items:center;justify-content:center;">
                    <img src="./assets/${item.model}.png" alt="${item.model}" style="max-width:100%;max-height:100%;" onerror="handleImageError(this)">
                 </div>
                
                <div class="item-title" onclick="openRenameModal('${actualId}', '${displayName}')" style="cursor:pointer; text-decoration:underline; font-size: 1.2rem; margin-bottom: 5px;">
                    ${displayName} <i class="fas fa-pen" style="font-size:0.8rem; margin-left:5px; color:#5c4a32;"></i>
                </div>
                
                <div style="font-size:0.9rem; color:#5c4a32; margin-bottom:15px; font-weight:bold;">Age: ${displayAge}</div>
                
                <button class="item-btn" type="button" onclick="window.spawnSpecificAnimal('${actualId}')">Spawn</button>
            `;

            livestockContent.appendChild(div);
        });
    }
    livestockMenu.classList.remove('hidden');
}

// Rename Variables
let currentRenameId = null;

function openRenameModal(animalId, currentName) {
    currentRenameId = animalId;
    const input = document.getElementById('rename-input');
    input.value = currentName;
    document.getElementById('rename-modal').classList.remove('hidden');
    input.focus();
}

function closeRenameModal() {
    document.getElementById('rename-modal').classList.add('hidden');
    currentRenameId = null;
}

function submitRename() {
    if (!currentRenameId) return;

    const input = document.getElementById('rename-input');
    const newName = input.value.trim();

    if (!newName) return;

    // Post to Client
    fetch(`https://${GetParentResourceName()}/renameAnimal`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            animalId: currentRenameId,
            newName: newName
        })
    }).then(resp => resp.json()).then(resp => {
        // Refresh menu? For now just close, user will likely reopen to see changes or we could request refresh
        // But we don't have direct refresh trigger here easily without requesting data again.
        // Ideally we update the DOM directly for immediate feedback or close menu.
        closeRenameModal();
        closeMenu(); // Close main menu to force user to reopen and fetch fresh data effectively
    });
}

function openBossMenu(data) {
    hideAll();

    document.getElementById('ranch-name').innerText = data.name;
    document.getElementById('ranch-funds').innerText = "$" + data.funds;
    document.getElementById('ranch-employees').innerText = data.employees;
    document.getElementById('ranch-animals').innerText = data.animals;

    // Add Manage/Spawn Animals Button
    // Add Manage/Spawn Animals Card
    let spawnCard = document.getElementById('manage-herd-card');
    if (!spawnCard) {
        spawnCard = document.createElement('div');
        spawnCard.id = 'manage-herd-card';
        spawnCard.className = 'item-card';
        spawnCard.innerHTML = `
            <i class="fa-solid fa-cow card-icon"></i>
            <div class="item-title">Manage Herd</div>
            <button class="item-btn" onclick="postAction('getLivestock', {})">Open</button>
        `;
        bossMenu.querySelector('.ui-content').appendChild(spawnCard);
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

        <div class="status-info" style="color: #3e2723; font-weight: bold; font-size: 1.1rem; margin-top: 20px;">
            <span><strong>Age:</strong> ${data.age} days</span>
            <span><strong>Gender:</strong> ${data.gender}</span>
        </div>
        
        <div style="margin-top:15px; text-align:center; font-family:var(--body-font); font-weight:800; color: #3e2723; border-top: 1px solid #5d403755; padding-top: 15px; font-size: 1.2rem;">
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
    window.requestAnimationFrame(step);
}

function openCraftingMenu(recipes) {
    hideAll();

    window.currentRecipes = recipes;
    window.selectedRecipe = null;

    const listContainer = document.getElementById('crafting-list-container');
    const detailsPanel = document.getElementById('crafting-details-content');

    if (!listContainer || !detailsPanel) {
        console.error('Crafting containers not found');
        return;
    }

    listContainer.innerHTML = '';
    detailsPanel.innerHTML = '<div class="details-placeholder">Select a recipe</div>';

    // Sidebar list items
    recipes.forEach((recipe, index) => {
        const item = document.createElement('div');
        item.className = 'crafting-list-item';
        item.dataset.index = index;
        item.innerHTML = `
            <img src="./assets/${recipe.item}.png" alt="${recipe.label}" onerror="this.src='nui://rsg-inventory/html/images/${recipe.item}.png';">
            <span>${recipe.label}</span>
        `;
        item.onclick = () => selectRecipe(index);
        listContainer.appendChild(item);
    });

    // Select first item by default
    if (recipes.length > 0) {
        selectRecipe(0);
    }

    craftingMenu.classList.remove('hidden');
}

function selectRecipe(index) {
    const recipes = window.currentRecipes;
    if (!recipes || !recipes[index]) return;

    const recipe = recipes[index];
    window.selectedRecipe = recipe;
    window.selectedQuantity = 1;

    // Update active state in list
    document.querySelectorAll('.crafting-list-item').forEach((el, i) => {
        el.classList.toggle('active', i === index);
    });

    const detailsPanel = document.getElementById('crafting-details-content');
    if (!detailsPanel) return;

    const baseTime = recipe.time || 5000;

    // Build ingredients HTML
    let ingredientsHtml = '';
    recipe.ingredients.forEach(ing => {
        const label = ing.label || ing.item;
        ingredientsHtml += `
            <div class="ingredient-row">
                <span class="ing-qty" data-base="${ing.amount}">${ing.amount}x</span>
                <span class="ing-name">${label}</span>
            </div>
        `;
    });

    detailsPanel.innerHTML = `
        <div class="details-content">
            <div class="details-title">${recipe.label}</div>
            <div class="details-image">
                <img src="./assets/${recipe.item}.png" alt="${recipe.label}" onerror="this.src='nui://rsg-inventory/html/images/${recipe.item}.png';">
            </div>
            <div class="details-ingredients">
                <div class="req-label">Required</div>
                <div id="ingredients-container">
                    ${ingredientsHtml}
                </div>
            </div>
            <div class="details-controls">
                <div class="quantity-row">
                    <button class="qty-btn" onclick="adjustQuantity(-1)">-</button>
                    <input type="number" id="craft-qty-input" class="qty-input" value="1" min="1" max="100" onchange="adjustQuantity(0)">
                    <button class="qty-btn" onclick="adjustQuantity(1)">+</button>
                </div>
                <div class="time-display" id="craft-time-display">Time: ${baseTime / 1000}s</div>
                <button class="craft-btn" onclick="craftSelectedItem()">
                    <i class="fa-solid fa-hammer"></i> Craft
                </button>
            </div>
        </div>
    `;
}

function adjustQuantity(delta) {
    const input = document.getElementById('craft-qty-input');
    const timeDisplay = document.getElementById('craft-time-display');
    const ingredientContainer = document.getElementById('ingredients-container');

    if (!input) return;

    let val = parseInt(input.value) || 1;
    val += delta;
    if (val < 1) val = 1;
    if (val > 100) val = 100;
    input.value = val;
    window.selectedQuantity = val;

    if (timeDisplay && window.selectedRecipe) {
        const baseTime = window.selectedRecipe.time || 5000;
        const totalTime = (baseTime * val) / 1000;
        timeDisplay.innerHTML = `Time: ${totalTime}s`;
    }

    if (ingredientContainer) {
        const qtyElements = ingredientContainer.querySelectorAll('.ing-qty');
        qtyElements.forEach(el => {
            const baseAmount = parseInt(el.dataset.base) || 1;
            el.textContent = `${baseAmount * val}x`;
        });
    }
}

function craftSelectedItem() {
    if (!window.selectedRecipe) return;

    const item = window.selectedRecipe.item;
    const amount = window.selectedQuantity || 1;

    console.log("Crafting item:", item, "Amount:", amount);

    fetch(`https://${GetParentResourceName()}/craftItem`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            item: item,
            amount: amount
        })
    });

    closeMenu();
}

function openCraftModal(index) {
    const recipes = window.currentRecipes;
    if (!recipes || !recipes[index]) return;

    const recipe = recipes[index];
    window.selectedRecipe = recipe;
    window.selectedQuantity = 1;

    const baseTime = recipe.time || 5000;

    let ingredientsHtml = '';
    recipe.ingredients.forEach(ing => {
        const label = ing.label || ing.item;
        ingredientsHtml += `
            <div class="craft-modal-ingredient">
                <span class="qty" data-base="${ing.amount}">${ing.amount}x</span>
                <span>${label}</span>
            </div>
        `;
    });

    const overlay = document.createElement('div');
    overlay.className = 'craft-modal-overlay';
    overlay.id = 'craft-modal-overlay';
    overlay.innerHTML = `
        <div class="craft-modal">
            <div class="craft-modal-title">${recipe.label}</div>
            <img class="craft-modal-image" src="./assets/${recipe.item}.png" alt="${recipe.label}" onerror="this.src='nui://rsg-inventory/html/images/${recipe.item}.png';">
            <div class="craft-modal-ingredients">
                <div class="req-label">Required</div>
                <div id="modal-ingredients-container">
                    ${ingredientsHtml}
                </div>
            </div>
            <div class="craft-modal-controls">
                <div class="craft-modal-qty-row">
                    <button class="qty-btn" onclick="adjustModalQty(-1)">-</button>
                    <input type="number" id="modal-qty-input" class="qty-input" value="1" min="1" max="100" onchange="adjustModalQty(0)">
                    <button class="qty-btn" onclick="adjustModalQty(1)">+</button>
                </div>
                <div class="time-display" id="modal-time-display">Time: ${baseTime / 1000}s</div>
            </div>
            <div class="craft-modal-buttons">
                <button class="craft-modal-btn cancel" onclick="closeCraftModal()">Cancel</button>
                <button class="craft-modal-btn confirm" onclick="confirmCraft()">Craft</button>
            </div>
        </div>
    `;

    document.body.appendChild(overlay);
}

function adjustModalQty(delta) {
    const input = document.getElementById('modal-qty-input');
    const timeDisplay = document.getElementById('modal-time-display');
    const ingredientContainer = document.getElementById('modal-ingredients-container');

    if (!input) return;

    let val = parseInt(input.value) || 1;
    val += delta;
    if (val < 1) val = 1;
    if (val > 100) val = 100;
    input.value = val;
    window.selectedQuantity = val;

    if (timeDisplay && window.selectedRecipe) {
        const baseTime = window.selectedRecipe.time || 5000;
        const totalTime = (baseTime * val) / 1000;
        timeDisplay.innerHTML = `Time: ${totalTime}s`;
    }

    if (ingredientContainer) {
        const qtyElements = ingredientContainer.querySelectorAll('.qty');
        qtyElements.forEach(el => {
            const baseAmount = parseInt(el.dataset.base) || 1;
            el.textContent = `${baseAmount * val}x`;
        });
    }
}

function closeCraftModal() {
    const overlay = document.getElementById('craft-modal-overlay');
    if (overlay) {
        overlay.remove();
    }
}

function confirmCraft() {
    if (!window.selectedRecipe) return;

    const item = window.selectedRecipe.item;
    const amount = window.selectedQuantity || 1;

    console.log("Crafting item:", item, "Amount:", amount);

    fetch(`https://${GetParentResourceName()}/craftItem`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            item: item,
            amount: amount
        })
    });

    closeCraftModal();
    closeMenu();
}

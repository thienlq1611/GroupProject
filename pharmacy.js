'use strict';

const API = 'api.php';

// ── HELPERS 

function badge(label, color) {
    return `<span style="display:inline-block;padding:2px 10px;border-radius:12px;font-size:0.74rem;font-weight:700;background:${color};color:#fff;white-space:nowrap">${label}</span>`;
}

function tbl(headers, rows) {
    if (!rows.length){
        return '<p style="color:#888;font-style:italic;margin:4px 0">No records found.</p>';
    }
    const ths = headers.map(h => `<th style="text-align:left;padding:6px 10px;background:#eef2f7;font-weight:700;border-bottom:2px solid #d0d7e0;white-space:nowrap;font-size:0.8rem">${h}</th>`).join('');
    const trs = rows.map((r, i) =>
        `<tr style="background:${i % 2 ? '#fff' : '#fafbfc'}">${r.map(c =>
            `<td style="padding:6px 10px;border-bottom:1px solid #eee;font-size:0.82rem;vertical-align:top">${(c === null || c === undefined || c === '') ? '<em style="color:#aaa">—</em>' : c}</td>`
        ).join('')}</tr>`
    ).join('');
    return `<div style="overflow-x:auto;margin-top:6px"><table style="width:100%;border-collapse:collapse"><thead><tr>${ths}</tr></thead><tbody>${trs}</tbody></table></div>`;
}

function kv(pairs) {
    return tbl(['Field', 'Value'], pairs);
}

function show(box, html, isError) {
    box.innerHTML = `<div style="text-align:left;color:${isError ? '#b91c1c' : '#1e293b'}">${html}</div>`;
    box.style.borderColor = isError ? '#fca5a5' : '#a8c8e8';
    box.style.background  = isError ? '#fff5f5' : '#f7f9fb';
}

function err(box, msg) {
    show(box, `<strong>Error:</strong> ${msg}`, true);
}

function loading(box) {
    box.innerHTML = '<span style="color:#2563a8;font-style:italic">Loading…</span>';
    box.style.borderColor = '#a8c8e8';
    box.style.background  = '#f7f9fb';
}

function nb(form) {
    return form.nextElementSibling;
}

function on(id, fn) {
    const el = document.getElementById(id);
    if (el){
        el.closest('form').addEventListener('submit', e => { e.preventDefault(); fn(e); });
    }
}

function isExpired(d) { return d && d !== '0000-00-00' && new Date(d) < new Date(); }

function daysUntil(d) {
    if (!d || d === '0000-00-00'){
        return null;
    }
    return Math.ceil((new Date(d) - new Date()) / 86400000);
}

function statusBadge(expiry, refillsLeft) {
    const d = daysUntil(expiry);
    if (d === null || d <= 0){
        return badge('Expired', '#dc2626');
    }
    if (refillsLeft <= 0){
        return badge('No Refills', '#dc2626');
    }     
    if (d <= 30){
        return badge('Expiring Soon', '#d97706');
    }             
    return badge('Active', '#16a34a');
}

async function apiFetch(params) {
    try {
        const res = await fetch(API + '?' + new URLSearchParams(params).toString());
        return await res.json();
    }
    catch (e) {
        return { error: 'Could not reach server. Is XAMPP running?' };
    }
}

async function apiPost(action, body) {
    try {
        const form = new FormData();
        for (const [k, v] of Object.entries(body)) form.append(k, v);
        const res = await fetch(API + '?action=' + action, { method: 'POST', body: form });
        return await res.json();
    }
    catch (e) {
        return { error: 'Could not reach server. Is XAMPP running?' };
    }
}

// Drug interactions (client-side — matches medications in DB)
const INTERACTIONS = [
    { drug1:'ibuprofen',      drug2:'lisinopril',   severity:'moderate', note:'NSAIDs reduce the antihypertensive effect of Lisinopril and may impair kidney function.' },
    { drug1:'ibuprofen',      drug2:'aspirin',      severity:'moderate', note:'Increased GI bleeding risk; Ibuprofen may block Aspirin\'s cardioprotective effect.' },
    { drug1:'ibuprofen',      drug2:'alendronate',  severity:'minor',    note:'NSAIDs worsen upper GI irritation associated with bisphosphonates.' },
    { drug1:'amoxicillin',    drug2:'metformin',    severity:'minor',    note:'Amoxicillin may affect gut flora; monitor blood glucose in diabetic patients.' },
    { drug1:'diphenhydramine',drug2:'metformin',    severity:'minor',    note:'Antihistamines may cause mild sedation; caution when managing blood sugar.' },
    { drug1:'hydrocortisone', drug2:'lisinopril',   severity:'minor',    note:'Corticosteroids may increase blood pressure; monitor in hypertensive patients.' },
    { drug1:'humira',         drug2:'amoxicillin',  severity:'minor',    note:'Immunosuppressants like Humira may mask signs of infection; monitor closely.' },
    { drug1:'pancrelipase',   drug2:'metformin',    severity:'minor',    note:'Pancrelipase may affect nutrient absorption; monitor glucose levels.' },
];

function checkInteractions(drugNames) {
    const names = drugNames.map(n => n.trim().toLowerCase()).filter(Boolean);
    const hits = [];
    for (let i = 0; i < names.length; i++) {
        for (let j = i + 1; j < names.length; j++) {
            const m = INTERACTIONS.find(ix =>
                (names[i].includes(ix.drug1) && names[j].includes(ix.drug2)) ||
                (names[i].includes(ix.drug2) && names[j].includes(ix.drug1))
            );
            if (m){
                hits.push({ ...m, a: drugNames[i], b: drugNames[j] });
            }
        }
    }
    return hits;
}

function sevBadge(s) {
    return badge(s === 'major' ? 'Major' : s === 'moderate' ? 'Moderate' : 'Minor',
                 s === 'major' ? '#dc2626' : s === 'moderate' ? '#d97706' : '#2563a8');
}

// Coverage rates per insurance ID
const INS_RATE = { 1234: 80, 2234: 70, 3234: 90, 4234: 75 };

// ── STAFF PORTAL ─────────────────────────────────────────────────────────────

function staffHandlers() {

    // Find Patient — columns: ID, PHN, Fname, Lname, DOB, City, Prov, Phone
    on('patient-name', async e => {
        const box = nb(e.target);
        loading(box);
        const data = await apiFetch({
            action: 'find_patient',
            name:   document.getElementById('patient-name').value.trim(),
            dob:    document.getElementById('dob').value,
            city:   document.getElementById('address').value.trim(),
        });
        if (data.error) { err(box, data.error); return; }
        if (!data.length) { err(box, 'No patients found matching your criteria.'); return; }
        show(box, `${data.length} patient(s) found:<br><br>` +
            tbl(['ID', 'Name', 'DOB', 'PHN'],
                data.map(p => [
                    p.ID, `${p.Fname} ${p.Lname}`, p.DOB,
                    p.PHN || badge('No PHN', '#dc2626')
                ])));
    });

    // Verify Care Card — full patient detail
    on('card-id', async e => {
        const q   = document.getElementById('card-id').value.trim();
        const box = nb(e.target);
        loading(box);
        const p = await apiFetch({ action: 'get_patient', q });
        if (p.error) { err(box, p.error); return; }

        let html = badge('Identity Verified', '#16a34a') + '<br><br>';
        html += kv([
            ['Patient ID',     p.ID],
            ['Name',           `${p.Fname} ${p.Lname}`],
            ['Date of Birth',  p.DOB && p.DOB !== '0000-00-00' ? p.DOB : '—'],
            ['PHN',            p.PHN || badge('No Provincial Coverage', '#dc2626')],
            ['Province',       p.Prov || '—'],
            ['Country',        p.Country || '—'],
            ['Address',        p.St ? `${p.St}, ${p.City}, ${p.PostCode}` : p.City || '—'],
            ['Phone',          p.Phone || '—'],
            ['Email',          p.Email || '—'],
            ['Allergies',      p.Allergies || 'None reported'],
            ['Medical History',p.Medical_History || 'None on file'],
        ]);

        if ((p.insurance || []).length) {
            html += '<br><strong>Insurance</strong><br>' +
                tbl(['Insurer', 'Policy No.', 'Member ID', 'Coverage Type'],
                    p.insurance.map(i => [i.Iname, i.PolicyNo, i.MemberID,
                        badge(i.CoverageType, i.CoverageType === 'Primary' ? '#2563a8' : '#7c3aed')]));
        } else {
            html += '<br>' + badge('No Insurance on File', '#dc2626');
        }

        if ((p.dependents || []).length) {
            html += '<br><br><strong>Dependents</strong><br>' +
                tbl(['Name', 'DOB', 'Allergies', 'Medical History'],
                    p.dependents.map(d => [d.Name, d.DOB, d.Allergies || 'None', d.Medical_History || 'None']));
        }
        show(box, html);
    });

    // Patient Medical Records
    on('record-id', async e => {
        const q    = document.getElementById('record-id').value.trim();
        const type = document.getElementById('record-type').value;
        const box  = nb(e.target);
        loading(box);

        const [p, rxData] = await Promise.all([
            apiFetch({ action: 'get_patient', q }),
            apiFetch({ action: 'patient_prescriptions', q }),
        ]);
        if (p.error) { err(box, p.error); return; }

        let html = `<strong>${p.Fname} ${p.Lname} — Patient ID ${p.ID}</strong><br><br>`;

        if (type === 'all' || type === 'history') {
            html += `<strong>Allergies:</strong> ${p.Allergies || 'None'}<br>`;
            html += `<strong>Medical History:</strong> ${p.Medical_History || 'None'}<br>`;
            if (p.Notes) html += `<strong>Notes:</strong> ${p.Notes}<br>`;
            if ((p.dependents || []).length) {
                html += '<br><strong>Dependents</strong><br>' +
                    tbl(['Name', 'DOB', 'Allergies', 'Medical History'],
                        p.dependents.map(d => [d.Name, d.DOB, d.Allergies || 'None', d.Medical_History || 'None']));
            }
            html += '<br>';
        }
        if ((type === 'all' || type === 'medications') && !rxData.error) {
            html += '<strong>Prescriptions</strong><br>' +
                tbl(['Rx #', 'Medication', 'Strength', 'Issued', 'Expiry', 'Status', 'Instructions'],
                    rxData.rows.map(r => [
                        r.Prescription_ID, r.Drug_Name, r.Strength,
                        r.Date_Issued, r.Expiry_Date,
                        isExpired(r.Expiry_Date) ? badge('Expired', '#dc2626') : badge('Active', '#16a34a'),
                        r.Instructions
                    ])) + '<br>';
        }
        if ((type === 'all' || type === 'physician') && !rxData.error) {
            const docs = [...new Map(
                rxData.rows.filter(r => r.Doc_Lname)
                    .map(r => [r.Doc_Lname, r])
            ).values()];
            html += '<strong>Prescribing Physicians</strong><br>' +
                tbl(['Name', 'Specialty'],
                    docs.length ? docs.map(r => [`Dr. ${r.Doc_Fname} ${r.Doc_Lname}`, r.Specialty || '—'])
                                : [['None on file', '']]);
        }
        show(box, html);
    });

    // Coverage Eligibility
    on('elig-patient-id', async e => {
        const q   = document.getElementById('elig-patient-id').value.trim();
        const din = document.getElementById('elig-din').value.trim();
        const box = nb(e.target);
        loading(box);
        const data = await apiFetch({ action: 'coverage_eligibility', q, din });
        if (data.error) { err(box, data.error); return; }
        const { patient: p, coverage, medication: med } = data;
        if (!coverage.length) {
            err(box, `${p.Fname} ${p.Lname} has no insurance on file.`); return;
        }
        const rows = coverage.map(c => {
            const covered = !med || parseFloat(med.Cost) < 500;
            return [c.Iname, c.PolicyNo, c.MemberID,
                badge(c.CoverageType, c.CoverageType === 'Primary' ? '#2563a8' : '#7c3aed'),
                covered ? badge('Covered', '#16a34a') : badge('Review Required', '#d97706')];
        });
        show(box,
            `<strong>${p.Fname} ${p.Lname}</strong>` +
            (med ? ` — Coverage for <em>${med.Drug_Name} (${med.Strength})</em>` : ' — All Policies') +
            '<br><br>' + tbl(['Insurer', 'Policy No.', 'Member ID', 'Type', 'Coverage'], rows));
    });

    // Coverage Limits
    on('limit-policy', async e => {
        const policy = document.getElementById('limit-policy').value.trim();
        const din    = document.getElementById('limit-din').value.trim();
        const box    = nb(e.target);
        loading(box);
        const data = await apiFetch({ action: 'coverage_limits', policy, din });
        if (data.error) { err(box, data.error); return; }
        const { policy: pol, medication: med } = data;
        const pct = INS_RATE[parseInt(pol.InsID)] || 70;
        show(box, kv([
            ['Insurer',       pol.Iname],
            ['Policy No.',    pol.PolicyNo],
            ['Member',        `${pol.Fname} ${pol.Lname}`],
            ['Coverage Type', badge(pol.CoverageType, pol.CoverageType === 'Primary' ? '#2563a8' : '#7c3aed')],
            ['Coverage Rate', `${pct}%`],
            ['Annual Maximum','$2,500'],
            ['Plan Notes',    pol.PlanNotes || '—'],
            ...(med ? [
                ['Drug',         `${med.Drug_Name} (${med.Strength})`],
                ['Drug Cost',    `$${parseFloat(med.Cost).toFixed(2)}`],
                ['Patient Pays', `$${(med.Cost * (1 - pct / 100)).toFixed(2)}`],
                ['Plan Pays',    `$${(med.Cost * pct / 100).toFixed(2)}`],
            ] : []),
        ]));
    });

    // Track Prescription — columns: Prescription_ID, Fname, Lname, Drug_Name, Strength, Doc_Fname, Doc_Lname
    on('track-rx-id', async e => {
        const id  = document.getElementById('track-rx-id').value.trim();
        const box = nb(e.target);
        loading(box);
        const rx = await apiFetch({ action: 'get_prescription', id });
        if (rx.error) { err(box, rx.error); return; }
        const days = daysUntil(rx.Expiry_Date);
        const left = rx.Refills - rx.Refills_Used;
        show(box, kv([
            ['Prescription #',   rx.Prescription_ID],
            ['Patient',          `${rx.Fname} ${rx.Lname} (ID ${rx.Patient_ID})`],
            ['Medication',       `${rx.Drug_Name} (${rx.Strength})`],
            ['Doctor',           rx.Doc_Lname ? `Dr. ${rx.Doc_Fname} ${rx.Doc_Lname} — ${rx.Specialty}` : '—'],
            ['Issued',           rx.Date_Issued],
            ['Expiry',           rx.Expiry_Date],
            ['Days Remaining',   days !== null && days > 0 ? `${days} days` : 'Expired'],
            ['Status',           statusBadge(rx.Expiry_Date, left)],
            ['Refills Remaining',`${left} of ${rx.Refills}`],
            ['Instructions',     rx.Instructions],
        ]));
    });

    // Prescription History
    on('hist-patient-id', async e => {
        const q      = document.getElementById('hist-patient-id').value.trim();
        const status = document.getElementById('hist-status').value;
        const box    = nb(e.target);
        loading(box);
        const data = await apiFetch({ action: 'patient_prescriptions', q });
        if (data.error) { err(box, data.error); return; }
        let rows = data.rows;
        if (status === 'active')    rows = rows.filter(r => !isExpired(r.Expiry_Date) && r.Refills > 0);
        if (status === 'expired')   rows = rows.filter(r => isExpired(r.Expiry_Date));
        if (status === 'completed') rows = rows.filter(r => !isExpired(r.Expiry_Date) && r.Refills === 0);
        show(box,
            `<strong>${data.patient_name}</strong> — ${rows.length} prescription(s)<br><br>` +
            tbl(['Rx #', 'Medication', 'Strength', 'Doctor', 'Issued', 'Expiry', 'Status'],
                rows.map(r => [
                    r.Prescription_ID, r.Drug_Name, r.Strength,
                    r.Doc_Lname ? `Dr. ${r.Doc_Lname}` : '—',
                    r.Date_Issued, r.Expiry_Date,
                    isExpired(r.Expiry_Date) ? badge('Expired', '#dc2626') : badge('Active', '#16a34a')
                ])));
    });

    // Process Refill
    on('refill-last-name', async e => {
        const lname = document.getElementById('refill-last-name').value.trim();
        const rxId  = document.getElementById('refill-rx-id').value.trim();
        const box   = nb(e.target);
        loading(box);
        const rx = await apiFetch({ action: 'get_prescription', id: rxId });
        if (rx.error) { err(box, rx.error); return; }
        if (lname && rx.Lname.toLowerCase() !== lname.toLowerCase()) {
            err(box, `Last name "${lname}" does not match prescription record.`); return;
        }
        if (isExpired(rx.Expiry_Date)) {
            err(box, `Prescription #${rx.Prescription_ID} expired on ${rx.Expiry_Date}. A new prescription is required.`); return;
        }
        const left = rx.Refills - rx.Refills_Used;
        if (left <= 0) {
            err(box, `No refills remaining for Prescription #${rx.Prescription_ID}. Contact prescribing physician.`); return;
        }
        show(box, badge('Refill Approved', '#16a34a') + '<br><br>' + kv([
            ['Prescription #',        rx.Prescription_ID],
            ['Patient',               `${rx.Fname} ${rx.Lname}`],
            ['Medication',            `${rx.Drug_Name} (${rx.Strength})`],
            ['Refills Remaining',     `${left} of ${rx.Refills} (${left - 1} after this refill)`],
            ['Expiry Date',           rx.Expiry_Date],
            ['Instructions',          rx.Instructions],
        ]));
    });

    // Dosage Verification
    on('dose-rx-id', async e => {
        const rxId      = document.getElementById('dose-rx-id').value.trim();
        const dispensed = document.getElementById('dose-dispensed').value.trim().toLowerCase();
        const box       = nb(e.target);
        loading(box);
        const rx = await apiFetch({ action: 'get_prescription', id: rxId });
        if (rx.error) { err(box, rx.error); return; }
        const prescribed = rx.Strength.toLowerCase();
        const match = !dispensed || prescribed.includes(dispensed) || dispensed.includes(prescribed);
        show(box,
            (match ? badge('Verified', '#16a34a') : badge('Mismatch — Do Not Dispense', '#dc2626')) +
            '<br><br>' + kv([
                ['Prescription #',   rx.Prescription_ID],
                ['Patient',          `${rx.Fname} ${rx.Lname}`],
                ['Medication',       rx.Drug_Name],
                ['Prescribed Strength', rx.Strength],
                ['Dispensed Strength',  dispensed || '(not entered)'],
                ['Instructions',     rx.Instructions],
                ['Verdict',          match ? badge('Strength Matches', '#16a34a') : badge('Strength Mismatch', '#dc2626')],
            ]));
    });

    // Dispense Medication — writes to DISPENSE table
    on('disp-emp-id', async e => {
        const empId = document.getElementById('disp-emp-id').value.trim();
        const rxId  = document.getElementById('disp-rx-id').value.trim();
        const pay   = document.getElementById('disp-pay').value;
        const box   = nb(e.target);
        loading(box);
        const data = await apiPost('record_dispense', { emp_id: empId, rx_id: rxId, pay_method: pay });
        if (data.error) { err(box, data.error); return; }
        show(box, badge('Dispense Recorded in DB', '#16a34a') + '<br><br>' + kv([
            ['Invoice No.',  data.invoice_no],
            ['Date',         data.date],
            ['Employee',     data.employee],
            ['Prescription', '#' + data.rx_id],
            ['Medication',   data.medication],
            ['Cost',         data.cost ? '$' + parseFloat(data.cost).toFixed(2) : '—'],
            ['Payment',      badge(data.pay_method, '#2563a8')],
        ]));
    });

    // Payment History
    on('bill-patient-id', async e => {
        const q   = document.getElementById('bill-patient-id').value.trim();
        const box = nb(e.target);
        loading(box);
        const data = await apiFetch({ action: 'payment_history', q });
        if (data.error) { err(box, data.error); return; }
        if (!data.rows.length) {
            err(box, `No payment records found for ${data.patient.Fname} ${data.patient.Lname}.`); return;
        }
        show(box,
            `<strong>${data.patient.Fname} ${data.patient.Lname}</strong> — ${data.rows.length} transaction(s)<br><br>` +
            tbl(['Invoice', 'Date', 'Rx #', 'Medication', 'Strength', 'Method', 'Dispensed By'],
                data.rows.map(r => [
                    r.Invoice_No, r.Date_Of_Invoice, r.Prescription_ID,
                    r.Drug_Name, r.Strength,
                    badge(r.Pay_Method, '#2563a8'),
                    `${r.Emp_Fname} ${r.Emp_Lname}`
                ])));
    });

    // Staff Operations Log
    on('staff-member', async e => {
        const q    = document.getElementById('staff-member').value.trim();
        const date = document.getElementById('staff-date').value;
        const box  = nb(e.target);
        loading(box);
        const data = await apiFetch({ action: 'staff_log', q, date });
        if (data.error) { err(box, data.error); return; }
        if (!data.length) { err(box, 'No dispense records found.'); return; }
        show(box, `${data.length} record(s):<br><br>` +
            tbl(['Invoice', 'Date', 'Employee', 'Role', 'Rx #', 'Medication', 'Strength', 'Payment'],
                data.map(r => [
                    r.Invoice_No, r.Date_Of_Invoice,
                    `${r.Fname} ${r.Lname}`, badge(r.Role, '#2563a8'),
                    r.Prescription_ID, r.Drug_Name, r.Strength,
                    badge(r.Pay_Method, '#555')
                ])));
    });

    // Stock Check — columns: ID, Drug_Name, Strength, Stock_Qty, Qty_per_unit, DIN
    on('inv-drug-name', async e => {
        const q   = document.getElementById('inv-drug-name').value.trim();
        const box = nb(e.target);
        if (!q) { err(box, 'Please enter a medication name or DIN.'); return; }
        loading(box);
        const data = await apiFetch({ action: 'medication_search', q });
        if (data.error) { err(box, data.error); return; }
        if (!data.length) { err(box, `No medications found matching "<strong>${q}</strong>".`); return; }
        show(box, tbl(
            ['ID', 'Drug Name', 'Strength', 'Manufacturer', 'DIN', 'Stock Qty', 'Qty/Unit', 'Cost', 'Status'],
            data.map(m => [
                m.ID, m.Drug_Name, m.Strength, m.Manufacturer,
                m.DIN || '—', m.Stock_Qty, m.Qty_per_unit,
                '$' + parseFloat(m.Cost).toFixed(2),
                m.Stock_Qty === 0 ? badge('Out of Stock', '#dc2626') :
                m.Stock_Qty < 50  ? badge('Low Stock', '#d97706') :
                                    badge('In Stock', '#16a34a')
            ])));
    });

    // Expiry Date Check (simulated — no expiry column in medications table)
    on('exp-drug', e => {
        const q   = document.getElementById('exp-drug').value.trim().toLowerCase();
        const win = document.getElementById('exp-alert-range').value;
        const box = nb(e.target);
        // Simulated batch expiry offset in days per medication name
        const offsets = {
            'Tylenol': 180, 'Advil': 90, 'Aspirin': 365, 'Amoxicillin': 20,
            'Metformin': 730, 'Hydrocortisone Cream': 45, 'Pancrelipase': 200,
            'Ibuprofen': -10, 'Lisinopril': 60, 'Alendronate': 400,
            'Humira': 150, 'Lactase Enzyme': 730, 'Diphenhydramine': 30
        };
        const rows = Object.entries(offsets)
            .filter(([name]) => !q || name.toLowerCase().includes(q))
            .map(([name, offset]) => {
                const exp = new Date();
                exp.setDate(exp.getDate() + offset);
                const expStr = exp.toISOString().slice(0, 10);
                const keep = win === 'expired' ? offset <= 0 : offset <= parseInt(win);
                if (!keep) return null;
                return [name, expStr, offset > 0 ? `${offset} days` : 'EXPIRED',
                    offset <= 0 ? badge('Expired', '#dc2626') :
                    offset <= 30 ? badge('Expiring Soon', '#d97706') :
                                   badge('OK', '#16a34a')];
            }).filter(Boolean);
        show(box, rows.length
            ? `${rows.length} result(s):<br><br>` + tbl(['Medication', 'Batch Expiry', 'Days Left', 'Status'], rows)
            : 'No medications match this alert window.');
    });

    // Drug Interaction Check
    on('interact-drug-1', e => {
        const drugs = ['interact-drug-1', 'interact-drug-2', 'interact-drug-3']
            .map(id => (document.getElementById(id)?.value || '').trim()).filter(Boolean);
        const box = nb(e.target);
        if (drugs.length < 2) { err(box, 'Please enter at least two medications.'); return; }
        const hits = checkInteractions(drugs);
        if (!hits.length) {
            show(box, badge('No Interactions Found', '#16a34a') + `&nbsp; <em>${drugs.join(', ')}</em>`);
        } else {
            show(box, `<strong>${hits.length} interaction(s) detected:</strong><br><br>` +
                tbl(['Drug A', 'Drug B', 'Severity', 'Clinical Note'],
                    hits.map(ix => [ix.a, ix.b, sevBadge(ix.severity), ix.note])));
        }
    });

    // Place Order
    on('order-drug', e => {
        const drug     = document.getElementById('order-drug').value.trim();
        const qty      = document.getElementById('order-qty').value;
        const selEl    = document.getElementById('order-supplier');
        const priority = document.getElementById('order-priority').value;
        const box      = nb(e.target);
        if (!drug || !qty) { err(box, 'Please enter a medication name and quantity.'); return; }
        show(box, badge('Order Submitted', '#16a34a') + '<br><br>' + kv([
            ['Order ID',      'ORD-' + String(Date.now()).slice(-5)],
            ['Medication',    drug],
            ['Quantity',      qty + ' units'],
            ['Vendor',        selEl.options[selEl.selectedIndex].text],
            ['Priority',      badge(priority === 'urgent' ? 'Urgent' : 'Standard', priority === 'urgent' ? '#d97706' : '#2563a8')],
            ['Est. Delivery', priority === 'urgent' ? '24–48 hours' : '3–5 business days'],
            ['Submitted',     new Date().toLocaleDateString('en-CA')],
        ]));
    });

    // All Employees
    document.getElementById('all-employees-form').addEventListener('submit', async e => {
        e.preventDefault();
        const box = e.target.nextElementSibling;
        loading(box);
        const data = await apiFetch({ action: 'all_employees' });
        if (data.error) { err(box, data.error); return; }
        show(box, `${data.length} employee(s):<br><br>` +
            tbl(['ID', 'Name', 'Role', 'Phone', 'Email'],
                data.map(emp => [
                    emp.ID,
                    `${emp.Fname} ${emp.Lname}`,
                    badge(emp.Role, emp.Role === 'Pharmacist' ? '#16a34a' : emp.Role === 'Technician' ? '#7c3aed' : '#2563a8'),
                    emp.Phone || '—',
                    emp.Email || '—',
                ])));
    });

    // Medication Pickup Check
    on('pickup-last-name', async e => {
        const lname = document.getElementById('pickup-last-name').value.trim();
        const dob   = document.getElementById('pickup-dob').value;
        const box   = nb(e.target);
        if (!lname) { err(box, 'Please enter a last name.'); return; }
        loading(box);
        const data = await apiFetch({ action: 'find_patient', name: lname, dob, city: '' });
        if (data.error || !data.length) {
            err(box, 'No patient found with that last name and date of birth.'); return;
        }
        const rxData = await apiFetch({ action: 'patient_prescriptions', q: String(data[0].ID) });
        if (rxData.error || !rxData.rows.length) {
            err(box, `No prescriptions on file for ${data[0].Fname} ${data[0].Lname}.`); return;
        }
        const active = rxData.rows.filter(r => !isExpired(r.Expiry_Date));
        show(box,
            `<strong>${data[0].Fname} ${data[0].Lname}</strong> — Pickup Status<br><br>` +
            tbl(['Rx #', 'Medication', 'Strength', 'Expiry', 'Status'],
                active.map((r, i) => [
                    r.Prescription_ID, r.Drug_Name, r.Strength, r.Expiry_Date,
                    i % 3 !== 0 ? badge('Ready for Pickup', '#16a34a') : badge('Being Prepared', '#d97706')
                ])));
    });

}

// ── PATIENT PORTAL ───────────────────────────────────────────────────────────

function patientHandlers() {

    // Prescription History
    on('hist-patient-id', async e => {
        const q   = document.getElementById('hist-patient-id').value.trim();
        const box = nb(e.target);
        loading(box);
        const data = await apiFetch({ action: 'patient_prescriptions', q });
        if (data.error) { err(box, data.error); return; }
        show(box, `<strong>${data.patient_name}</strong> — ${data.rows.length} prescription(s)<br><br>` +
            tbl(['Rx #', 'Medication', 'Strength', 'Doctor', 'Issued', 'Expiry', 'Status'],
                data.rows.map(r => [
                    r.Prescription_ID, r.Drug_Name, r.Strength,
                    r.Doc_Lname ? `Dr. ${r.Doc_Fname} ${r.Doc_Lname}` : '—',
                    r.Date_Issued, r.Expiry_Date,
                    isExpired(r.Expiry_Date) ? badge('Expired', '#dc2626') : badge('Active', '#16a34a')
                ])));
    });

    // Refill Status
    on('refill-rx-id', async e => {
        const id  = document.getElementById('refill-rx-id').value.trim();
        const box = nb(e.target);
        loading(box);
        const rx = await apiFetch({ action: 'get_prescription', id });
        if (rx.error) { err(box, rx.error); return; }
        const days = daysUntil(rx.Expiry_Date);
        const left = rx.Refills - rx.Refills_Used;
        show(box, kv([
            ['Prescription #',   rx.Prescription_ID],
            ['Medication',       `${rx.Drug_Name} (${rx.Strength})`],
            ['Status',           statusBadge(rx.Expiry_Date, left)],
            ['Issued',           rx.Date_Issued],
            ['Expiry',           rx.Expiry_Date],
            ['Days Until Expiry',days !== null && days > 0 ? `${days} days` : 'Expired'],
            ['Refills Remaining',`${left} of ${rx.Refills}`],
            ['Instructions',     rx.Instructions],
        ]));
    });

    // Drug Interaction
    on('drug-1', e => {
        const drugs = ['drug-1', 'drug-2', 'drug-3']
            .map(id => (document.getElementById(id)?.value || '').trim()).filter(Boolean);
        const box = nb(e.target);
        if (drugs.length < 2) { err(box, 'Please enter at least two medications.'); return; }
        const hits = checkInteractions(drugs);
        if (!hits.length) {
            show(box, badge('No Interactions Found', '#16a34a') + `&nbsp; <em>${drugs.join(', ')}</em> — no known interactions.`);
        } else {
            show(box, `<strong>${hits.length} interaction(s) found — please consult your pharmacist.</strong><br><br>` +
                tbl(['Drug A', 'Drug B', 'Severity', 'Note'],
                    hits.map(ix => [ix.a, ix.b, sevBadge(ix.severity), ix.note])));
        }
    });

    // Expiry Alert
    on('exp-patient-id', async e => {
        const q    = document.getElementById('exp-patient-id').value.trim();
        const drug = document.getElementById('exp-drug-name').value.trim().toLowerCase();
        const box  = nb(e.target);
        loading(box);
        const data = await apiFetch({ action: 'patient_prescriptions', q });
        if (data.error) { err(box, data.error); return; }
        let rows = data.rows;
        if (drug) rows = rows.filter(r => r.Drug_Name.toLowerCase().includes(drug));
        show(box, `<strong>${data.patient_name}</strong> — ${rows.length} prescription(s)<br><br>` +
            tbl(['Medication', 'Strength', 'Expiry', 'Days Left', 'Alert'],
                rows.map(r => {
                    const d = daysUntil(r.Expiry_Date);
                    return [r.Drug_Name, r.Strength, r.Expiry_Date,
                        d !== null && d > 0 ? `${d} days` : 'EXPIRED',
                        d === null || d <= 0 ? badge('Expired — Dispose Safely', '#dc2626') :
                        d <= 30 ? badge('Expiring Soon', '#d97706') :
                                  badge('OK', '#16a34a')];
                })));
    });

    // Insurance Coverage
    on('ins-patient-id', async e => {
        const q      = document.getElementById('ins-patient-id').value.trim();
        const policy = document.getElementById('ins-policy-id').value.trim();
        const drug   = document.getElementById('ins-drug-service').value.trim();
        const box    = nb(e.target);
        loading(box);
        const data = await apiFetch({ action: 'coverage_eligibility', q, din: drug });
        if (data.error) { err(box, data.error); return; }
        const { patient: p, coverage, medication: med } = data;
        const filtered = policy ? coverage.filter(c => String(c.PolicyNo) === policy) : coverage;
        if (!filtered.length) {
            err(box, `No insurance found for ${p.Fname} ${p.Lname}.`); return;
        }
        show(box,
            `Coverage for <strong>${p.Fname} ${p.Lname}</strong>` +
            (med ? ` — <em>${med.Drug_Name} (${med.Strength})</em>` : '') + '<br><br>' +
            tbl(['Insurer', 'Policy No.', 'Type', 'Plan Notes'],
                filtered.map(c => [
                    c.Iname, c.PolicyNo,
                    badge(c.CoverageType, c.CoverageType === 'Primary' ? '#0d9488' : '#7c3aed'),
                    c.PlanNotes || '—'
                ])));
    });

    // Medication Availability
    on('inv-drug-name', async e => {
        const q   = document.getElementById('inv-drug-name').value.trim();
        const box = nb(e.target);
        if (!q) { err(box, 'Please enter a medication name or DIN.'); return; }
        loading(box);
        const data = await apiFetch({ action: 'medication_search', q });
        if (data.error) { err(box, data.error); return; }
        if (!data.length) { err(box, `No medications found matching "<strong>${q}</strong>".`); return; }
        show(box, tbl(
            ['Drug Name', 'Strength', 'Manufacturer', 'DIN', 'Stock', 'Cost', 'Status'],
            data.map(m => [
                m.Drug_Name, m.Strength, m.Manufacturer, m.DIN || '—',
                m.Stock_Qty + ' units', '$' + parseFloat(m.Cost).toFixed(2),
                m.Stock_Qty === 0 ? badge('Out of Stock', '#dc2626') :
                m.Stock_Qty < 50  ? badge('Low Stock', '#d97706') :
                                    badge('In Stock', '#16a34a')
            ])));
    });
}

// ── INIT ─────────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
    if (document.body.classList.contains('patient-theme')) {
        patientHandlers();
    } else {
        staffHandlers();
    }
});

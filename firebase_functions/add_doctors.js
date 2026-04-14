const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

const doctors = [
    {
      'name': 'Dr. Yahya El-Adawy Shousha',
      'email': 'dr.yahya@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Mohamed Sabry',
      'email': 'dr.mohamed.sabry@nbig.com',
      'specialty': 'Ophthalmology',
    },
    {
      'name': 'Dr. Maher Hassan Aglan',
      'email': 'dr.maher@nbig.com',
      'specialty': 'Surgery',
    },
    {
      'name': 'Dr. Mohamed Sayed Taha Sawi',
      'email': 'dr.mohamed.sawi@nbig.com',
      'specialty': 'General Practice',
    },
    {
      'name': 'Dr. Hazem Abdelrahman',
      'email': 'dr.hazem@nbig.com',
      'specialty': 'General Practice',
    },
    {
      'name': 'Dr. Heba Farid Ali',
      'email': 'dr.heba@nbig.com',
      'specialty': 'Investment',
    },
    {
      'name': 'Dr. Ashraf Mohamed Thabet',
      'email': 'dr.ashraf@nbig.com',
      'specialty': 'General Practice',
    },
    {
      'name': 'Dr. Shawky Abdelrahman',
      'email': 'dr.shawky@nbig.com',
      'specialty': 'General Practice',
    },
    {
      'name': 'Dr. Samira Shaaban',
      'email': 'dr.samira@nbig.com',
      'specialty': 'Dentistry & General',
    },
    {
      'name': 'Dr. Hoda Ali El-Sayed',
      'email': 'dr.hoda@nbig.com',
      'specialty': 'Orthopedics & Pediatrics',
    },
    {
      'name': 'Dr. Sameh Abdel Tawab',
      'email': 'dr.sameh@nbig.com',
      'specialty': 'Ophthalmology',
    },
    {
      'name': 'Dr. Mohamed Ali Saleh',
      'email': 'dr.mohamed.saleh@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Taher Mohamed Hassan Eissa',
      'email': 'dr.taher@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Mohamed Nada Abdel Naby',
      'email': 'dr.mohamed.nada@nbig.com',
      'specialty': 'General Practice',
    },
    {
      'name': 'Dr. Atef',
      'email': 'dr.atef@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Ali Salah',
      'email': 'dr.ali.salah@nbig.com',
      'specialty': 'General Medicine',
    },
    {
      'name': 'Dr. Mohamed Mostafa',
      'email': 'dr.mohamed.mostafa@nbig.com',
      'specialty': 'Obstetrics & Gynecology',
    },
    {
      'name': 'Dr. Ahmed Shawkat Mohamed',
      'email': 'dr.ahmed.shawkat@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Ahmed Abdel Raouf',
      'email': 'dr.ahmed.raouf@nbig.com',
      'specialty': 'Investment',
    },
    {
      'name': 'Dr. Nadia El-Meligy',
      'email': 'dr.nadia@nbig.com',
      'specialty': 'Dermatology & Cosmetology',
    },
    {
      'name': 'Dr. Suhaila Ahmed Mahmoud',
      'email': 'dr.suhaila@nbig.com',
      'specialty': 'General Practice',
    },
    {
      'name': 'Dr. Shahd Sarmad',
      'email': 'dr.shahd.sarmad@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Ahmed Mohamed Thabet',
      'email': 'dr.ahmed.thabet@nbig.com',
      'specialty': 'Dermatology & Cosmetology',
    },
    {
      'name': 'Dr. Mowafi Mohamed Dahab',
      'email': 'dr.mowafi@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Alaa Abdelhamid Sabry',
      'email': 'dr.alaa@nbig.com',
      'specialty': 'General Medicine',
    },
    {
      'name': 'Dr. Afaf Ahmed',
      'email': 'dr.afaf@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Ghada Abdelmoneim',
      'email': 'dr.ghada@nbig.com',
      'specialty': 'Dermatology & Cosmetology',
    },
    {
      'name': 'Dr. Mohamed Atef Abdelaziz',
      'email': 'dr.mohamed.atef@nbig.com',
      'specialty': 'Dentistry',
    },
    {
      'name': 'Dr. Waleed Abdelmoneim',
      'email': 'dr.waleed@nbig.com',
      'specialty': 'Dentistry & General',
    },
    {
      'name': 'Dr. Sahar Abdelhalim',
      'email': 'dr.sahar@nbig.com',
      'specialty': 'Pediatric Dentistry',
    },
    {
      'name': 'Dr. Asmaa Mohamed Maher',
      'email': 'dr.asmaa@nbig.com',
      'specialty': 'General Practice',
    },
    {
      'name': 'Dr. Reda Abdel-Aal',
      'email': 'dr.reda@nbig.com',
      'specialty': 'ENT',
    },
    {
      'name': 'Dr. Essam Abu El-Makarim',
      'email': 'dr.essam@nbig.com',
      'specialty': 'Physical Therapy',
    },
    {
      'name': 'Dr. Khaled',
      'email': 'dr.khaled@nbig.com',
      'specialty': 'Investment',
    },
    {
      'name': 'Dr. Alia',
      'email': 'dr.alia@nbig.com',
      'specialty': 'Psychiatry',
    }
];

async function addDocs() {
  let created = 0;
  for (let d of doctors) {
    try {
      const snap = await db.collection("users").where("email", "==", d.email).get();
      if (snap.empty) {
        // Assume user doesn't exist, we will just create a dummy one
        const userRef = db.collection("users").doc();
        await userRef.set({
           email: d.email, role: 'doctor', name: d.name, createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        created++;
      }
    } catch(e) { console.error(e); }
  }
  console.log(`Done. created: ${created}`);
}

addDocs().then(() => process.exit(0));

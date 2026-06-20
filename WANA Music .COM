<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>WANA Music Player</title>

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

<style>
:root{
    --bg:#020617;
    --surface:#0f172a;
    --card:#1e293b;
    --card-hover:#273449;
    --primary:#8b5cf6;
    --primary-light:#a78bfa;
    --text:#f8fafc;
    --muted:#94a3b8;
    --border:rgba(255,255,255,.08);
}

*{
    margin:0;
    padding:0;
    box-sizing:border-box;
    font-family:'Inter',sans-serif;
}

body{
    min-height:100vh;
    color:var(--text);
    background:
        radial-gradient(circle at top left, rgba(139,92,246,.18), transparent 35%),
        radial-gradient(circle at top right, rgba(59,130,246,.12), transparent 30%),
        linear-gradient(180deg, #020617, #0f172a);
}

body::before{
    content:"";
    position:fixed;
    inset:0;
    background-image:
        linear-gradient(rgba(255,255,255,.02) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255,255,255,.02) 1px, transparent 1px);
    background-size:40px 40px;
    pointer-events:none;
}

.container{
    width:min(1150px,92%);
    margin:auto;
}

header{
    text-align:center;
    padding:60px 0 30px;
}

header h1{
    font-size:clamp(2.5rem,5vw,4rem);
    font-weight:800;
    margin-bottom:12px;
}

header p{
    color:var(--muted);
    max-width:600px;
    margin:auto;
    line-height:1.7;
}

.upload-area{
    display:flex;
    justify-content:center;
    margin:20px 0 40px;
}

.upload-btn{
    border:none;
    cursor:pointer;
    color:white;
    padding:16px 28px;
    border-radius:18px;
    font-size:1rem;
    font-weight:700;
    background:linear-gradient(135deg,var(--primary),var(--primary-light));
    box-shadow:0 12px 30px rgba(139,92,246,.35);
    transition:.25s ease;
}

.upload-btn:hover{
    transform:translateY(-4px);
}

#musicUpload{
    display:none;
}

.playlist{
    display:grid;
    grid-template-columns:repeat(auto-fill,minmax(280px,1fr));
    gap:20px;
    padding-bottom:180px;
}

.track-card{
    background:rgba(30,41,59,.75);
    backdrop-filter:blur(12px);
    border:1px solid var(--border);
    border-radius:22px;
    padding:20px;
    transition:.25s ease;
}

.track-card:hover{
    transform:translateY(-6px);
    background:var(--card-hover);
}

.track-card.active{
    border-color:rgba(139,92,246,.8);
    box-shadow:0 0 30px rgba(139,92,246,.2);
}

.track-icon{
    width:64px;
    height:64px;
    border-radius:18px;
    display:flex;
    align-items:center;
    justify-content:center;
    background:rgba(139,92,246,.15);
    font-size:2rem;
    margin-bottom:16px;
}

.track-name{
    font-weight:700;
    margin-bottom:10px;
    word-break:break-word;
}

.track-info{
    color:var(--muted);
    font-size:.9rem;
    margin-bottom:18px;
}

.play-btn{
    width:100%;
    border:none;
    cursor:pointer;
    padding:12px;
    border-radius:12px;
    font-weight:700;
    color:white;
    background:var(--primary);
    transition:.2s;
}

.play-btn:hover{
    filter:brightness(1.1);
}

.empty-state{
    grid-column:1/-1;
    text-align:center;
    color:var(--muted);
    padding:60px 20px;
}

.player{
    position:fixed;
    left:50%;
    bottom:20px;
    transform:translateX(-50%);
    width:min(900px,95%);
    padding:18px;
    background:rgba(15,23,42,.92);
    backdrop-filter:blur(20px);
    border:1px solid var(--border);
    border-radius:26px;
    box-shadow:0 20px 60px rgba(0,0,0,.4);
}

.now-playing{
    display:flex;
    justify-content:space-between;
    align-items:center;
    gap:20px;
    margin-bottom:15px;
}

.track-details{
    min-width:0;
}

.track-details small{
    display:block;
    color:var(--muted);
    margin-bottom:4px;
}

.track-details h3{
    overflow:hidden;
    text-overflow:ellipsis;
    white-space:nowrap;
}

.controls{
    display:flex;
    align-items:center;
    gap:10px;
}

.controls button{
    width:46px;
    height:46px;
    border:none;
    border-radius:50%;
    background:var(--primary);
    color:white;
    cursor:pointer;
    font-size:1rem;
    transition:.2s;
}

.controls button:hover{
    transform:scale(1.05);
}

audio{
    width:100%;
}

.visualizer{
    display:flex;
    gap:4px;
    height:30px;
    align-items:flex-end;
}

.bar{
    width:4px;
    border-radius:20px;
    background:var(--primary-light);
    animation:bounce 1s infinite ease-in-out;
}

.bar:nth-child(2){animation-delay:.1s;}
.bar:nth-child(3){animation-delay:.2s;}
.bar:nth-child(4){animation-delay:.3s;}
.bar:nth-child(5){animation-delay:.4s;}

@keyframes bounce{
    0%,100%{height:8px;}
    50%{height:28px;}
}

.paused .bar{
    animation-play-state:paused;
    height:8px;
}

@media(max-width:700px){
    .now-playing{
        flex-direction:column;
        align-items:flex-start;
    }
}
</style>
</head>

<body>

<header class="container">
    <h1>🎵 WANA Music Player</h1>
    <p>
        Build your own playlist from local music files, enjoy autoplay,
        next and previous controls, and a live visualizer.
    </p>
</header>

<div class="container">

    <div class="upload-area">
        <button class="upload-btn" id="uploadBtn">
            📁 Choose Music Files
        </button>

        <input
            id="musicUpload"
            type="file"
            accept="audio/*"
            multiple>
    </div>

    <div class="playlist" id="playlist">
        <div class="empty-state" id="emptyState">
            No music selected yet. Click <strong>Choose Music Files</strong> to start building your playlist.
        </div>
    </div>

</div>

<div class="player">

    <div class="now-playing">

        <div class="track-details">
            <small>Now Playing</small>
            <h3 id="currentTrack">Nothing selected</h3>
        </div>

        <div class="controls">
            <button id="prevBtn">⏮</button>

            <div class="visualizer paused" id="visualizer">
                <div class="bar"></div>
                <div class="bar"></div>
                <div class="bar"></div>
                <div class="bar"></div>
                <div class="bar"></div>
            </div>

            <button id="nextBtn">⏭</button>
        </div>

    </div>

    <audio id="audioPlayer" controls></audio>

</div>

<script>
const uploadBtn = document.getElementById('uploadBtn');
const musicUpload = document.getElementById('musicUpload');
const playlist = document.getElementById('playlist');
const emptyState = document.getElementById('emptyState');

const audioPlayer = document.getElementById('audioPlayer');
const currentTrack = document.getElementById('currentTrack');

const prevBtn = document.getElementById('prevBtn');
const nextBtn = document.getElementById('nextBtn');
const visualizer = document.getElementById('visualizer');

const songs = [];
let currentIndex = -1;

uploadBtn.addEventListener('click', () => {
    musicUpload.click();
});

function updateActiveCard() {
    document.querySelectorAll('.track-card').forEach((card, index) => {
        card.classList.toggle('active', index === currentIndex);

        const button = card.querySelector('.play-btn');
        button.textContent = index === currentIndex
            ? '🎧 Playing'
            : '▶ Play';
    });
}

function playSong(index) {
    if (index < 0 || index >= songs.length) return;

    currentIndex = index;

    audioPlayer.src = songs[index].url;
    audioPlayer.play();

    currentTrack.textContent = songs[index].name;

    updateActiveCard();
}

musicUpload.addEventListener('change', (e) => {

    const files = Array.from(e.target.files);

    if (!files.length) return;

    emptyState.style.display = 'none';

    const shouldAutoPlay = songs.length === 0;

    files.forEach(file => {

        if (!file.type.startsWith('audio/')) return;

        const song = {
            name: file.name,
            size: (file.size / 1024 / 1024).toFixed(2),
            url: URL.createObjectURL(file)
        };

        songs.push(song);

        const index = songs.length - 1;

        const card = document.createElement('div');
        card.className = 'track-card';

        card.innerHTML = `
            <div class="track-icon">🎵</div>
            <div class="track-name">${song.name}</div>
            <div class="track-info">${song.size} MB</div>
            <button class="play-btn">▶ Play</button>
        `;

        card.querySelector('.play-btn').addEventListener('click', () => {
            playSong(index);
        });

        playlist.appendChild(card);
    });

    if (shouldAutoPlay) {
        playSong(0);
    }

    musicUpload.value = '';
});

nextBtn.addEventListener('click', () => {

    if (!songs.length) return;

    let next = currentIndex + 1;

    if (next >= songs.length) {
        next = 0;
    }

    playSong(next);
});

prevBtn.addEventListener('click', () => {

    if (!songs.length) return;

    let prev = currentIndex - 1;

    if (prev < 0) {
        prev = songs.length - 1;
    }

    playSong(prev);
});

audioPlayer.addEventListener('ended', () => {

    if (!songs.length) return;

    let next = currentIndex + 1;

    if (next >= songs.length) {
        next = 0;
    }

    playSong(next);
});

audioPlayer.addEventListener('play', () => {
    visualizer.classList.remove('paused');
});

audioPlayer.addEventListener('pause', () => {
    visualizer.classList.add('paused');
});
</script>

</body>
</html>
```

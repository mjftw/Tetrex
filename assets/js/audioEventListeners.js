// Play an audio element on demand
window.addEventListener("phx:play-audio", e => {
    let audio = document.getElementById(e.detail.id)
    audio.muted = false
    audio.play()
})

// Pause an audio element on demand
window.addEventListener("phx:pause-audio", e => {
    let audio = document.getElementById(e.detail.id)
    audio.pause()
})
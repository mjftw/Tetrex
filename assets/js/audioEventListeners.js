// Play an audio element on demand
window.addEventListener("phx:play-audio", e => {
    let audio = document.getElementById(e.detail.id)
    audio.play()
})

// Stop an audio element on demand
window.addEventListener("phx:stop-audio", e => {
    let audio = document.getElementById(e.detail.id)
    audio.currentTime = 0
    audio.pause()
})

// Pause an audio element on demand
window.addEventListener("phx:pause-audio", e => {
    let audio = document.getElementById(e.detail.id)
    audio.pause()
})

// Mute audio source on demand
window.addEventListener("phx:mute-audio", e => {
    let audioElements = document.getElementsByTagName("audio")
    let audio = document.getElementById(e.detail.id)
    audio.muted = true
})

// Unmute audio source on demand
window.addEventListener("phx:unmute-audio", e => {
    let audio = document.getElementById(e.detail.id)
    audio.muted = false
})
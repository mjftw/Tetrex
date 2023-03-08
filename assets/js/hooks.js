let Hooks = {
    TouchInput: {
        // TODO: Work out why hooks aren't working
        mounted() {
            console.log("MOUNTED")
            window.addEventListener("touchstart", e => {
                e.preventDefault();
                this.pushTargetEvent("touchstart", e);
            }, { passive: false })

            window.addEventListener("touchmove", e => {
                e.preventDefault();
                this.pushTargetEvent("touchmove", e);
            }, { passive: false })

            window.addEventListener("touchend", e => {
                e.preventDefault();
                this.pushTargetEvent("touchend", e);
            }, { passive: false })

            window.addEventListener("touchcancel", e => {
                e.preventDefault();
                this.pushTargetEvent("touchcancel", e);
            }, { passive: false })
        }
    }
}
export default Hooks;
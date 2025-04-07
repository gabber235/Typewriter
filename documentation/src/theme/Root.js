import React from "react";
import CookieConsent from "react-cookie-consent";

// Default implementation, that you can customize
export default function Root({ children }) {
    // Custom styles for the CookieConsent component
    const cookieConsentStyles = {
        container: {
            background: "#37454a",
            color: "#fff",
            padding: "10px",
        },
        button: {
            color: "#fff",
            fontSize: "16px",
            background: "#4CAF50",
            borderRadius: "5px",
            padding: "10px 20px",
        },
        declineButton: {
            color: "#fff",
            background: "#f44336",
            fontSize: "16px",
            borderRadius: "5px",
            padding: "10px 20px",
        },
        content: {
            margin: "10px",
        },
        overlay: {
            background: "rgba(0,0,0,0.7)",
        },
    };

    return (
        <>
            <CookieConsent
                visible="byCookieValue"
                location="bottom"
                buttonText="Accept"
                declineButtonText="Decline"
                cookieName="TypeWriterCookieConcent"
                style={cookieConsentStyles.container}
                buttonStyle={cookieConsentStyles.button}
                declineButtonStyle={cookieConsentStyles.declineButton}
                contentStyle={cookieConsentStyles.content}
                overlay
                overlayStyle={cookieConsentStyles.overlay}
                expires={150}
                onAccept={() => {
                    try {
                        // Custom accept logic
                        console.log("Cookies accepted!");
                    } catch (error) {
                        console.error("Error accepting cookies:", error);
                    }
                }}
                onDecline={() => {
                    try {
                        // Custom decline logic
                        console.log("Cookies declined!");
                        window.location.href = "/leave";
                    } catch (error) {
                        console.error("Error declining cookies:", error);
                    }
                }}
                enableDeclineButton
                flipButtons
                ariaAcceptLabel="Accept cookies"
                ariaDeclineLabel="Decline cookies"
            >
                This website uses cookies to enhance the user experience.{" "}
                <span style={{ fontSize: "10px" }}>
                    <a href="/privacy-policy" style={{ color: "#f1d600" }}>
                        Learn more
                    </a>
                </span>
            </CookieConsent>
            {children}
        </>
    );
}

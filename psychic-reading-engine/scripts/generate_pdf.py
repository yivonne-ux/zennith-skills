#!/usr/bin/env python3
"""
PDF Report Generator for Psychic Readings
Creates beautiful, personalized PDF reports with:
- Cover page with name and birth data
- Tarot section with card images and interpretations
- QMDJ section with chart visualization
- Western astrology section with planetary positions
- Synthesis and actionable guidance
- Upsell CTA
"""

import json
import sys
from datetime import datetime
from fpdf import FPDF, XPos, YPos
from pathlib import Path


class PsychicReadingPDF(FPDF):
    """PDF generator for psychic reading reports"""

    def __init__(self, reading_data):
        super().__init__()
        self.reading = reading_data
        self.setup_page()

    def setup_page(self):
        """Setup PDF with brand colors and fonts"""
        self.add_page()
        # Dark theme with gold accents
        self.set_auto_page_break(auto=True, margin=20)
        self.set_font('Helvetica', 'B', 14)

    def add_cover_page(self):
        """Create beautiful cover page"""
        # Background
        self.set_fill_color(20, 20, 30)
        self.rect(0, 0, self.w, self.h, 'F')

        # Title
        self.set_xy(0, self.h / 2 - 30)
        self.set_text_color(255, 215, 0)  # Gold
        self.set_font('Helvetica', 'B', 48)
        self.cell(0, 0, 'PSYCHIC READING', align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(10)
        self.cell(0, 0, 'for', align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(5)

        # Customer name
        name = self.reading.get('reading_for', 'Unknown')
        self.set_text_color(200, 200, 255)
        self.set_font('Helvetica', 'B', 56)
        self.cell(0, 0, name, align='C', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(30)

        # Generated date
        self.set_font('Helvetica', '', 14)
        self.set_text_color(150, 150, 150)
        generated_at = self.reading.get('generated_at', '')
        if generated_at:
            self.cell(0, 0, f'Generated: {generated_at}', align='C')

        self.ln(100)

        # Decorative elements
        for i in range(3):
            # Golden color with varying intensity
            intensity = 100 + i * 30
            color = min(255, intensity)
            self.set_text_color(255, color, color)
            self.set_font('Helvetica', 'B', 20 + i * 10)
            self.cell(0, 0, '*', align='C')

    def add_section_header(self, title, confidence=None):
        """Add section header with styling"""
        self.set_font('Helvetica', 'B', 24)
        self.set_text_color(255, 215, 0)
        self.cell(0, 15, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.line(20, self.y - 10, self.w - 20, self.y - 10)

        if confidence is not None:
            self.set_font('Helvetica', 'I', 12)
            self.set_text_color(150, 150, 150)
            self.cell(0, 5, f'Confidence: {confidence}%', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        self.ln(5)

    def add_core_insight(self, insight):
        """Add core insight section"""
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(200, 200, 255)
        self.cell(0, 10, 'Core Insight', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(2)

        self.set_font('Helvetica', '', 11)
        self.set_text_color(220, 220, 240)
        # Remove non-ASCII characters for PDF compatibility
        clean_insight = insight.encode('ascii', 'ignore').decode('ascii')
        self.multi_cell(0, 6, clean_insight)
        self.ln(8)

    def add_supporting_evidence(self, evidence_list):
        """Add supporting evidence list"""
        if not evidence_list:
            return

        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(180, 180, 200)
        self.cell(0, 8, 'Supporting Evidence:', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(3)

        self.set_font('Helvetica', '', 10)
        self.set_text_color(160, 160, 180)

        for item in evidence_list:
            self.cell(15, 5, '-', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            evidence_text = item.get('data', '')
            system = item.get('system', '')
            if system:
                evidence_text = f'[{system}] {evidence_text}'
            clean_evidence = evidence_text.encode('ascii', 'ignore').decode('ascii')
            self.multi_cell(0, 5, clean_evidence)
            self.ln(4)

        self.ln(6)

    def add_barnum_layer(self, barnum_list):
        """Add Barnum/Forer layer with reflective statements"""
        if not barnum_list:
            return

        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(180, 180, 200)
        self.cell(0, 8, 'Deeper Reflections:', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(3)

        self.set_font('Helvetica', 'I', 11)
        self.set_text_color(180, 180, 200)
        for statement in barnum_list:
            self.cell(15, 5, '>', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            clean_statement = statement.encode('ascii', 'ignore').decode('ascii')
            self.multi_cell(0, 6, f' {clean_statement}')
            self.ln(4)

        self.ln(6)

    def add_cross_system_themes(self, themes):
        """Add cross-system themes section"""
        if not themes:
            return

        self.add_section_header('Cross-System Themes')
        self.set_font('Helvetica', 'B', 13)
        self.set_text_color(255, 215, 0)

        for theme in themes:
            self.set_font('Helvetica', 'B', 12)
            self.set_text_color(180, 180, 200)
            theme_name = theme.get('theme_name', 'Unknown').replace('_', ' ').title()
            self.cell(0, 8, f'{theme_name}', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

            confidence = theme.get('confidence', 0)
            self.set_font('Helvetica', '', 10)
            self.set_text_color(150, 150, 150)
            self.cell(0, 5, f'{confidence}% convergence', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            self.ln(2)

            self.set_font('Helvetica', '', 10)
            self.set_text_color(220, 220, 240)
            interpretation = theme.get('interpretation', '')
            clean_interpretation = self.clean_text(interpretation)
            self.multi_cell(0, 5, clean_interpretation)
            self.ln(4)

            evidence = theme.get('evidence', [])
            if evidence:
                self.set_font('Helvetica', 'I', 10)
                self.set_text_color(160, 160, 180)
                for ev in evidence:
                    self.cell(15, 5, '-', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
                    self.multi_cell(0, 5, f' {ev}')
                self.ln(4)

        self.ln(8)

    def add_tarot_section(self):
        """Add tarot section with card representations"""
        self.add_section_header('Tarot Reading')
        self.set_font('Helvetica', 'I', 11)
        self.set_text_color(160, 160, 180)

        note = 'The tarot cards selected for this reading reflect your current energetic patterns and potential future trajectories.'
        self.multi_cell(0, 5, note)
        self.ln(8)

        # Note about card images placeholder
        self.set_font('Helvetica', 'B', 11)
        self.set_text_color(255, 215, 0)
        self.cell(0, 8, 'Card Images:', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(3)

        self.set_font('Helvetica', 'I', 10)
        self.set_text_color(150, 150, 150)
        self.cell(15, 5, '-', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.multi_cell(0, 5, 'Card images would be displayed here from your tarot deck.')
        self.ln(4)

        self.cell(15, 5, '-', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.multi_cell(0, 5, 'See interpretation in each section above.')
        self.ln(8)

    def add_astrology_section(self):
        """Add Western astrology section"""
        self.add_section_header('Western Astrology')
        self.set_font('Helvetica', 'I', 11)
        self.set_text_color(160, 160, 180)

        systems = self.reading.get('systems_used', [])
        if systems:
            systems_text = ", ".join(systems)
            self.multi_cell(0, 5, self.clean_text(f'Systems Used: {systems_text}'))

        self.ln(8)

        # Add all astrological sections
        for section in self.reading.get('sections', []):
            if section.get('section') in ['overview', 'love', 'career', 'health', 'spiritual']:
                self.add_section_detail(section)

        self.ln(8)

    def add_qmdj_section(self):
        """Add QMDJ section with chart information"""
        self.add_section_header('Qi Men Dun Jia (QMDJ)')
        self.set_font('Helvetica', 'I', 11)
        self.set_text_color(160, 160, 180)

        note = 'The QMDJ chart combines Chinese cosmological systems with traditional feng shui principles. This ancient method analyzes time, space, and destiny.'
        self.multi_cell(0, 5, note)
        self.ln(8)

        # Note about chart visualization placeholder
        self.set_font('Helvetica', 'B', 11)
        self.set_text_color(255, 215, 0)
        self.cell(0, 8, 'Chart Visualization:', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(3)

        self.set_font('Helvetica', 'I', 10)
        self.set_text_color(150, 150, 150)
        self.cell(15, 5, '-', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.multi_cell(0, 5, 'QMDJ palace chart would be displayed here.')
        self.ln(4)

        self.cell(15, 5, '-', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.multi_cell(0, 5, 'Includes 9 palaces, 8 doors, 9 stars, and temporal gates.')
        self.ln(8)

    def clean_text(self, text):
        """Remove non-ASCII characters for PDF compatibility"""
        if not text:
            return ""
        clean_text = text.encode('ascii', 'ignore').decode('ascii')
        return clean_text

    def add_section_detail(self, section):
        """Add detail for a specific astrological section"""
        self.ln(4)
        self.add_section_header(section.get('section', '').title())

        core_insight = section.get('core_insight', '')
        if core_insight:
            self.add_core_insight(core_insight)

        self.add_supporting_evidence(section.get('supporting_evidence', []))
        self.add_barnum_layer(section.get('barnum_layer', []))
        self.add_cold_reading(section.get('cold_reading', []))

        confidence = section.get('confidence_level', 0)
        timing = section.get('timing_window', '')
        if timing:
            self.set_font('Helvetica', '', 10)
            self.set_text_color(150, 150, 150)
            clean_timing = self.clean_text(timing)
            self.cell(0, 5, f'Timing: {clean_timing} | Confidence: {confidence}%', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        self.ln(6)

    def add_cold_reading(self, cold_list):
        """Add cold reading statements"""
        if not cold_list:
            return

        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(180, 180, 200)
        self.cell(0, 8, 'Personal Insights:', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(3)

        self.set_font('Helvetica', '', 10)
        self.set_text_color(160, 160, 180)

        for statement in cold_list:
            self.cell(15, 5, '-', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            clean_statement = statement.encode('ascii', 'ignore').decode('ascii')
            self.multi_cell(0, 5, clean_statement)
            self.ln(4)

        self.ln(6)

    def add_synthesis_and_advice(self):
        """Add synthesis and actionable advice section"""
        self.add_section_header('Synthesis & Guidance')

        self.set_font('Helvetica', 'B', 13)
        self.set_text_color(255, 215, 0)
        self.cell(0, 8, 'Overall Interpretation', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(3)

        self.set_font('Helvetica', '', 11)
        self.set_text_color(220, 220, 240)

        overall_confidence = self.reading.get('overall_confidence', 0)
        self.multi_cell(0, 5, f'This reading synthesizes multiple systems with {overall_confidence}% overall confidence.')

        self.ln(8)

        self.set_font('Helvetica', 'B', 13)
        self.set_text_color(255, 215, 0)
        self.cell(0, 8, 'Actionable Guidance', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(3)

        # Find advice section
        advice = None
        for section in self.reading.get('sections', []):
            if section.get('section') == 'advice':
                advice = section
                break

        if advice:
            core_insight = advice.get('core_insight', '')
            if core_insight:
                self.add_core_insight(core_insight)

            self.add_supporting_evidence(advice.get('supporting_evidence', []))
            self.add_barnum_layer(advice.get('barnum_layer', []))
            self.add_cold_reading(advice.get('cold_reading', []))
        else:
            self.set_font('Helvetica', '', 11)
            self.set_text_color(200, 200, 220)
            self.multi_cell(0, 5, 'Actionable insights from this reading guide your decisions and actions moving forward.')

        self.ln(10)

    def add_cta_section(self):
        """Add upsell call-to-action section"""
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(255, 215, 0)
        self.cell(0, 15, 'EXPLORE DEEPER', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.line(20, self.y - 10, self.w - 20, self.y - 10)
        self.ln(8)

        self.set_font('Helvetica', '', 11)
        self.set_text_color(200, 200, 220)

        cta_text = """
This reading provides insights based on the planetary and tarot energy for this moment. For deeper, personalized guidance:
- 1-on-1 session with an AI psychic
- Detailed birth chart analysis ($49.99)
- 20-minute audio reading ($19.99)
- Monthly psychic subscription ($29.99)
- Mentorship program ($497.00)

Your readings contain entertainment value only. Always consult qualified professionals for life decisions.
        """.strip()

        self.multi_cell(0, 6, cta_text)
        self.ln(10)

    def add_footer(self):
        """Add footer with branding and disclaimer"""
        self.set_y(-15)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(100, 100, 120)

        page_num = self.page_no()
        self.cell(0, 10, f'Page {page_num}', align='C')

        self.ln(4)
        disclaimer = 'Entertainment purposes only. Not medical, legal, or financial advice.'
        self.multi_cell(0, 4, disclaimer, align='C')


def generate_pdf(reading_data, output_path):
    """Generate PDF from reading data"""
    pdf = PsychicReadingPDF(reading_data)

    # Add all sections
    pdf.add_cover_page()
    pdf.add_cross_system_themes(reading_data.get('cross_system_themes', []))

    pdf.add_tarot_section()
    pdf.add_astrology_section()
    pdf.add_qmdj_section()

    pdf.add_synthesis_and_advice()

    pdf.add_cta_section()

    # Add footer
    pdf.add_footer()

    # Save PDF
    pdf.output(output_path)
    return output_path


def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: generate_pdf.py <reading.json> [output.pdf]")
        sys.exit(1)

    reading_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else reading_path.replace('.json', '.pdf')

    # Load reading data
    with open(reading_path, 'r') as f:
        reading_data = json.load(f)

    print(f"Generating PDF from: {reading_path}")
    print(f"Output: {output_path}")

    # Generate PDF
    pdf_path = generate_pdf(reading_data, output_path)

    print(f"✅ PDF generated: {pdf_path}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
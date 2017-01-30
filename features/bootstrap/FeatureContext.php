<?php
use Behat\MinkExtension\Context\RawMinkContext;
use Behat\Behat\Tester\Exception\PendingException;
use Behat\Gherkin\Node\PyStringNode;
use Behat\Gherkin\Node\TableNode;
use Behat\Behat\Context\SnippetAcceptingContext;
/**
 * Defines application features from the specific context.
 */
class FeatureContext extends RawMinkContext implements SnippetAcceptingContext
{
    var $breakpoints = [];

    /**
     * Convenience mappings for human language:
     *
     * ... when I scroll to the <mapping>
     * ... I should see the <mapping>
     */
    var $mappings = [];

    /**
     * Initializes context.
     *
     * Every scenario gets its own context instance.
     * You can also pass arbitrary arguments to the
     * context constructor through behat.yml.
     */
    public function __construct()
    {
    }

    /**
     * @Given /^I am at "([^"]*)"$/
     */
    public function iAmAt($url)
    {
        $this->visitPath($url);
        throw new PendingException();
    }

    /**
     * Assertions
     * @param $selector
     * @param $message
     */
    protected function assertNotVisible( $selector, $message ) {
        assertTrue( $this->getSession()->evaluateScript( 'isnt_visible(' . json_encode( $selector ) . ')' ), $message );
    }
    protected function assertVisible( $selector, $message ) {
        assertTrue( $this->getSession()->evaluateScript( 'is_visible(' . json_encode( $selector ) . ')' ), $message );
    }

    /**
     * Map plain-language references to specific CSS elements
     * @param $el
     * @param bool $enforce
     * @return
     */
    protected function map( $el, $enforce = true ) {
        $normalized = strtolower( trim( $el ) );
        if( $enforce ) {
            assertTrue( isset( $this->mappings[$normalized] ), "Unknown mapping \"$el\" ($normalized)" );
        }
        if ( isset( $this->mappings[$normalized] ) ) {
            $el = $this->mappings[$normalized];
        }
        return $el;
    }

    /**
     * @Given the breakpoints:
     * @param TableNode $table
     */
    public function theBreakpoints(TableNode $table)
    {
        $hash = $table->getHash();
        $this->breakpoints = [];
        foreach( $hash as $row ) {
            $this->breakpoints[] = $row['breakpoint'];
        }
    }


    /**
     * @Then /^I take a screenshot with title "([^"]*)"$/
     */
    public function iTakeAScreenshotWithTitle($title)
    {
        $mink = $this->getMink();
        $driver = $mink->getSession()->getDriver();

        foreach( $this->breakpoints as $width ) {
            $this->getSession()->resizeWindow( (int) $width, 700 );

            $screenshot = $driver->getScreenshot();

            file_put_contents( 'text/results/screenshots/' . $title . '-' . $width . '.png', $screenshot );
        }
    }

    /**
     * @When /^I hover over (?P<selector>[^"]*)$/
     */
    public function iHoverOver($selector) {
        $css = $this->map( $selector );
        $this->getSession()->executeScript('jQuery(' . json_encode( $css ) . ').trigger("mouseover")');
    }

    /**
     * @Then /^I scroll to (\d+) pixels$/
     */
    public function whenIScrollToPixels($scroll)
    {
        $this->getSession()->executeScript('window.scrollTo(0, ' . $scroll . ')');
        usleep( 100 );
    }

    /**
     * @Then /^I scroll by (-?\d+) pixels$/
     */
    public function whenIScrollByNPixels($scroll)
    {
        $this->getSession()->executeScript('window.scroll_by(' . (int) $scroll . ')');
        usleep( 100 );
    }

    /**
     * @Then /^I scroll to "([^"]*)"/
     * @Then /^I scroll to the (.*)$/
     */
    public function whenIScrollTo($element)
    {
        $css = $this->map( $element, false );

        $nodes = $this->getSession()->getPage()->findAll('css', $css);

        assertNotEmpty( $nodes, "\"$element\" ($css) exists" );

        $this->getSession()->executeScript('window.scroll_to(' . json_encode( $css ) . ')');
    }

    /**
     * @When /^I wait (\d+) seconds$/
     */
    public function iWaitSeconds($seconds)
    {
        sleep($seconds);
    }

}